"""
This module store the class used for releasing targets
"""
# @TODO Write doc!
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'


class Release(object):
    def __init__(self, tag, data_link, niak_path, release=False):

        self.tag = tag
        self.data_link = data_link
        self.niak_path = niak_path

        self.build()

        if release:
            self.relese()

    def build(self):
        """
        build the target with niak_test_all

        Returns
        -------
        bool
            True if successful, False otherwise.
        """
        pass


    def release(self):
        """
        Pushes the tag to the repo and update niak_test_all and niak_gb_vars

        Returns
        -------
        bool
            True if successful, False otherwise.

        """
        pass


if __name__ == "__main__":
    pass