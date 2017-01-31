"""Utils and fixtures to facilitate operations on Oneprovider web GUI.
"""
from selenium.webdriver import ActionChains

from tests.gui.utils.generic import click_on_web_elem, find_web_elem

__author__ = "Jakub Liput"
__copyright__ = "Copyright (C) 2016 ACK CYFRONET AGH"
__license__ = "This software is released under the MIT license cited in " \
              "LICENSE.txt"


def assert_breadcrumbs_correctness(path, breadcrumbs):
    cwd = breadcrumbs.text.split()
    path = path.split('/')
    err_msg = '{} not found on {} position in breadcrumbs, instead we have {}'
    assert len(path) == len(cwd), 'found {} path in breadcrumbs ' \
                                  'instead of {}'.format(cwd, path)
    for i, (dir1, dir2) in enumerate(zip(path, cwd)):
        assert dir1 == dir2, err_msg.format(dir1, i, '/'.join(cwd))


def chdir_using_breadcrumbs(path, breadcrumbs):
    dir1, dir2 = None, None
    err_msg = '{} not found on {} position in breadcrumbs, instead we have {}'
    for i, (dir1, dir2) in enumerate(zip(path.split('/'), breadcrumbs)):
        assert dir1 == dir2.text, err_msg.format(dir1, i,
                                                 '/'.join(directory.text
                                                          for directory
                                                          in breadcrumbs)
                                                 )
    dir2.click()


# this function was blocking import of this module because of errors
# def current_dir(driver):
#     return RE_DATA_URL.match(
#         parse_url(driver.current_url).group('method')
#     ).group('dir')


class DataTab(object):
    def __init__(self, web_elem):
        self.web_elem = web_elem


import abc


class Expandable(object):
    __metaclass__ = abc.ABCMeta

    @property
    def is_expanded(self):
        toggle = self._get_toggle()
        return self._is_expanded(toggle)

    def expand(self):
        toggle = self._get_toggle()
        if not self._is_expanded(toggle):
            self._click_on_toggle(toggle)

    def collapse(self):
        toggle = self._get_toggle()
        if self._is_expanded(toggle):
            self._click_on_toggle(toggle)

    # noinspection PyMethodMayBeStatic
    def _is_expanded(self, toggle):
        aria_expanded = toggle.get_attribute('aria-expanded')
        return True if (aria_expanded and 'true' == aria_expanded) else False

    @abc.abstractmethod
    def _click_on_toggle(self, toggle):
        pass

    @abc.abstractmethod
    def _get_toggle(self):
        pass


class SpaceSelector(Expandable):
    def __init__(self, driver, web_elem):
        self._driver = driver
        self.web_elem = web_elem

    @property
    def current_selected_space_name(self):
        err_msg = 'unable to locate name label for current selected space in ' \
                  'data tab in op'
        label = find_web_elem(self.web_elem, '.item-label', err_msg)
        return label.text

    @property
    def is_current_selected_space_home(self):
        err_msg = 'unable to locate icon for space named "{}" currently ' \
                  'selected in data tab in ' \
                  'op'.format(self.current_selected_space_name)
        icon = find_web_elem(self.web_elem, '.item-icon .one-icon', err_msg)
        return 'oneicon-space-home' in icon.get_attribute('class')

    def _click_on_toggle(self, toggle):
        err_msg = 'clicking on toggle for space selector in data tab in op' \
                  'is disabled'
        click_on_web_elem(self._driver, toggle, err_msg)

    def _get_toggle(self):
        css_sel = 'a.dropdown-toggle'
        return self.web_elem.find_element_by_css_selector(css_sel)

    class SpaceRecord(object):
        def __init__(self, driver, web_elem):
            self._driver = driver
            self.web_elem = web_elem

        @property
        def name(self):
            err_msg = 'unable to locate name label for given space in ' \
                      'displayed space selector'
            label = find_web_elem(self.web_elem, '.item-label', err_msg)
            return label.text

        @property
        def is_home(self):
            err_msg = 'unable to locate icon for space named "{}" in ' \
                      'displayed space selector'.format(self.name)
            icon = find_web_elem(self.web_elem, '.item-icon .one-icon',
                                 err_msg)
            return 'oneicon-space-home' in icon.get_attribute('class')

        def click(self):
            err_msg = 'clicking on space named "{}" in space selector ' \
                      'in data tab in op disabled'.format(self.name)
            click_on_web_elem(self._driver, self.web_elem, err_msg)

    @property
    def spaces(self):
        if self.is_expanded:
            css_sel = 'ul.dropdown-menu-list li'
            return [SpaceSelector.SpaceRecord(self._driver, space)
                    for space
                    in self.web_elem.find_elements_by_css_selector(css_sel)]
        else:
            raise RuntimeError('dropdown menu for space selector in data '
                               'tab in op is not expanded')

    def __getitem__(self, space_name):
        for space in self.spaces:
            if space_name == space.name:
                return space
        else:
            raise RuntimeError('no space named "{space}" displayed in space '
                               'selector in data tab in op '
                               'found'.format(space=space_name))


class DirectoryTree(Expandable):
    def __init__(self, driver, web_elem, parent, children):
        self._driver = driver
        self.web_elem = web_elem
        self._parent = parent
        self._children = children

    @property
    def name(self):
        err_msg = 'unable to locate name label for given directory in ' \
                  'data tab sidebar in op'
        label = find_web_elem(self.web_elem, '.item-label', err_msg)
        return label.text

    @property
    def is_active(self):
        css_sel = '.secondary-sidebar-item.dir-item'
        err_msg = 'unable to locate header area for given directory in ' \
                  'data tab sidebar in op'
        item = find_web_elem(self.web_elem, css_sel, err_msg)
        return 'active' in item.get_attribute('class')

    def _click_on_toggle(self, toggle):
        err_msg = 'clicking on directory icon for "{}" directory in data tab ' \
                  'sidebar is disabled'.format(self.name)
        click_on_web_elem(self._driver, toggle, err_msg)

    def _get_toggle(self):
        css_sel = '.item-icon .one-icon'
        return self.web_elem.find_element_by_css_selector(css_sel)

    # noinspection PyMethodMayBeStatic
    def _is_expanded(self, toggle):
        return True if 'folder-open' in toggle.get_attribute('class') else False

    def pwd(self):
        if not self._parent:
            return '/'
        else:
            return '{path}{dir}/'.format(path=self._parent.pwd(),
                                         dir=self.name)

    def click(self):
        css_sel = '.secondary-sidebar-item.dir-item .item-click-area'
        err_msg = 'unable to locate clickable area for given directory in ' \
                  'data tab sidebar in op'
        item = find_web_elem(self.web_elem, css_sel, err_msg)
        click_on_web_elem(self._driver, item, 'clicking on {} directory '
                                              'disabled'.format(self.pwd()))

    @property
    def subdirectories(self):
        css_sel = 'ul.data-files-tree-list li'
        return [DirectoryTree(self._driver, dir_tree, self, dir_tree)
                for dir_tree
                in self._children.find_elements_by_css_selector(css_sel)]

    def __getitem__(self, name):
        if not self.is_expanded:
            self.expand()
        for directory in self.subdirectories:
            if directory.name == name:
                return directory
        else:
            raise RuntimeError('no subdirectory named "{name}" '
                               'in {path}'.format(name=name, path=self.pwd()))


class DataTabSidebar(object):
    def __init__(self, driver, web_elem, resize_handler):
        self._driver = driver
        self.web_elem = web_elem
        self._resize_handler = resize_handler

    @property
    def space_selector(self):
        css_sel = '.data-spaces-select'
        err_msg = 'unable to locate space selector in data tab in op'
        selector = find_web_elem(self.web_elem, css_sel, err_msg)
        return SpaceSelector(self._driver, selector)

    @property
    def width(self):
        return self._resize_handler.location['x']

    @width.setter
    def width(self, value):
        offset = value - self.width
        action = ActionChains(self._driver)
        action.drag_and_drop_by_offset(self._resize_handler, offset, 0)
        action.perform()

    @property
    def root_dir(self):
        css_sel = '.data-files-tree ul li'
        items = self.web_elem.find_elements_by_css_selector(css_sel)
        if len(items) < 2:
            raise RuntimeError('unable to locate root dir and its children in '
                               'directory tree sidebar in data tab in op')
        return DirectoryTree(self._driver, items[0], None, items[1])

    @property
    def cwd(self):
        cwd = self._cwd(self.root_dir)
        if cwd:
            return cwd
        else:
            raise RuntimeError('no working directory selected')

    def _cwd(self, curr_dir):
        if curr_dir.is_active:
            return curr_dir
        for directory in curr_dir.subdirectories:
            if directory.is_active:
                return directory
            else:
                cwd = self._cwd(directory)
                if cwd:
                    return cwd
