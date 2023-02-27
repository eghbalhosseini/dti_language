import itertools

import matplotlib.pyplot as plt
import numpy as np

from matplotlib import gridspec
from matplotlib.colorbar import make_axes
from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize, LinearSegmentedColormap
from mpl_toolkits.mplot3d import Axes3D  # noqa
from nilearn import image

from nilearn.plotting.img_plotting import _get_colorbar_and_data_ranges
from nilearn.surface import (load_surf_data,
                             load_surf_mesh,
                             vol_to_surf)
from nilearn.surface.surface import _check_mesh
from nilearn._utils import check_niimg_3d
from nilearn.plotting.js_plotting_utils import colorscale
from nilearn.plotting.html_surface import _get_vertexcolor
from nilearn.plotting import plot_surf
from matplotlib.colors import to_rgba
from matplotlib.patches import Patch
from mpl_toolkits.mplot3d.art3d import Poly3DCollection


def plot_surf_contours_eh(surf_mesh, roi_map, axes=None, figure=None, levels=None,
                       labels=None, colors=None, legend=False, cmap='tab20',
                       title=None, output_file=None, **kwargs):

    if figure is None and axes is None:
        figure = plot_surf(surf_mesh, **kwargs)
        axes = figure.axes[0]
    if figure is None:
        figure = axes.get_figure()
    if axes is None:
        axes = figure.axes[0]
    if axes.name != '3d':
        raise ValueError('Axes must be 3D.')
    # test if axes contains Poly3DCollection, if not initialize surface
    if not axes.collections or not isinstance(axes.collections[0],
                                              Poly3DCollection):
        _ = plot_surf(surf_mesh, axes=axes, **kwargs)

    coords, faces = load_surf_mesh(surf_mesh)
    roi = load_surf_data(roi_map)
    if levels is None:
        levels = np.unique(roi_map)
    if colors is None:
        n_levels = len(levels)
        vmax = n_levels
        cmap = plt.get_cmap(cmap)
        norm = Normalize(vmin=0, vmax=vmax)
        colors = [cmap(norm(color_i)) for color_i in range(vmax)]
    else:
        try:
            colors = [to_rgba(color, alpha=1.) for color in colors]
        except ValueError:
            raise ValueError('All elements of colors need to be either a'
                             ' matplotlib color string or RGBA values.')

    if labels is None:
        labels = [None] * len(levels)
    if not (len(levels) == len(labels) == len(colors)):
        raise ValueError('Levels, labels, and colors '
                         'argument need to be either the same length or None.')

    patch_list = []
    for level, color, label in zip(levels, colors, labels):
        roi_indices = np.where(roi == level)[0]
        faces_outside = _get_faces_on_edge(faces, roi_indices)
        # Fix: Matplotlib version 3.3.2 to 3.3.3
        # Attribute _facecolors3d changed to _facecolor3d in
        # matplotlib version 3.3.3
        try:
            axes.collections[0]._facecolors3d[faces_outside] = color
        except AttributeError:
            axes.collections[0]._facecolor3d[faces_outside] = color
        if label and legend:
            patch_list.append(Patch(color=color, label=label,linewidth=6,edgecolor=color))
    # plot legend only if indicated and labels provided
    if legend and np.any([lbl is not None for lbl in labels]):
        figure.legend(handles=patch_list)
        # if legends, then move title to the left
    if title is None and hasattr(figure._suptitle, "_text"):
        title = figure._suptitle._text
    if title:
        axes.set_title(title)
    # save figure if output file is given
    if output_file is not None:
        figure.savefig(output_file)
        plt.close(figure)
    else:
        return figure

def _get_faces_on_edge(faces, parc_idx):
    '''
    Internal function for identifying which faces lie on the outer
    edge of the parcellation defined by the indices in parc_idx.
    Parameters
    ----------
    faces : numpy.ndarray of shape (n, 3), indices of the mesh faces
    parc_idx : numpy.ndarray, indices of the vertices
        of the region to be plotted
    '''
    # count how many vertices belong to the given parcellation in each face
    verts_per_face = np.isin(faces, parc_idx).sum(axis=1)

    # test if parcellation forms regions
    if np.all(verts_per_face < 2):
        raise ValueError('Vertices in parcellation do not form region.')

    vertices_on_edge = np.intersect1d(np.unique(faces[verts_per_face == 2]),
                                      parc_idx)
    faces_outside_edge = np.isin(faces, vertices_on_edge).sum(axis=1)

    return np.logical_and(faces_outside_edge > 0, verts_per_face < 3)
