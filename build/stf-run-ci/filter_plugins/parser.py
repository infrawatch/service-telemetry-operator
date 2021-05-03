#!/usr/bin/python
class FilterModule(object):
    def filters(self):
        return {
            'parse_image': self.parse_image,
            'parse_tag': self.parse_tag
        }

    def parse_image(self, value):
        this_split = value.split(':')[:-1]
        return ':'.join(this_split)

    def parse_tag(self, value):
        return value.split(':')[-1]
