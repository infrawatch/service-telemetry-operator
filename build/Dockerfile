FROM quay.io/operator-framework/ansible-operator:v1.36.1

# temporarily switch to root user to adjust image layers
USER 0
# Upstream CI builds need the additional EPEL sources for python3-passlib and python3-bcrypt but have no working repos to install epel-release
# NO_PROXY is undefined in upstream CI builds, but defined (usually blank) during openshift builds (a possibly brittle hack)
RUN bash -c -- 'if [ "${NO_PROXY:-__ZZZZZ}" == "__ZZZZZ" ]; then echo "Applying upstream EPEL hacks" && echo -e "-----BEGIN PGP PUBLIC KEY BLOCK-----\nmQINBGE3mOsBEACsU+XwJWDJVkItBaugXhXIIkb9oe+7aadELuVo0kBmc3HXt/Yp\nCJW9hHEiGZ6z2jwgPqyJjZhCvcAWvgzKcvqE+9i0NItV1rzfxrBe2BtUtZmVcuE6\n2b+SPfxQ2Hr8llaawRjt8BCFX/ZzM4/1Qk+EzlfTcEcpkMf6wdO7kD6ulBk/tbsW\nDHX2lNcxszTf+XP9HXHWJlA2xBfP+Dk4gl4DnO2Y1xR0OSywE/QtvEbN5cY94ieu\nn7CBy29AleMhmbnx9pw3NyxcFIAsEZHJoU4ZW9ulAJ/ogttSyAWeacW7eJGW31/Z\n39cS+I4KXJgeGRI20RmpqfH0tuT+X5Da59YpjYxkbhSK3HYBVnNPhoJFUc2j5iKy\nXLgkapu1xRnEJhw05kr4LCbud0NTvfecqSqa+59kuVc+zWmfTnGTYc0PXZ6Oa3rK\n44UOmE6eAT5zd/ToleDO0VesN+EO7CXfRsm7HWGpABF5wNK3vIEF2uRr2VJMvgqS\n9eNwhJyOzoca4xFSwCkc6dACGGkV+CqhufdFBhmcAsUotSxe3zmrBjqA0B/nxIvH\nDVgOAMnVCe+Lmv8T0mFgqZSJdIUdKjnOLu/GRFhjDKIak4jeMBMTYpVnU+HhMHLq\nuDiZkNEvEEGhBQmZuI8J55F/a6UURnxUwT3piyi3Pmr2IFD7ahBxPzOBCQARAQAB\ntCdGZWRvcmEgKGVwZWw5KSA8ZXBlbEBmZWRvcmFwcm9qZWN0Lm9yZz6JAk4EEwEI\nADgWIQT/itE0RZcQbs6BO5GKOHK/MihGfAUCYTeY6wIbDwULCQgHAgYVCgkICwIE\nFgIDAQIeAQIXgAAKCRCKOHK/MihGfFX/EACBPWv20+ttYu1A5WvtHJPzwbj0U4yF\n3zTQpBglQ2UfkRpYdipTlT3Ih6j5h2VmgRPtINCc/ZE28adrWpBoeFIS2YAKOCLC\nnZYtHl2nCoLq1U7FSttUGsZ/t8uGCBgnugTfnIYcmlP1jKKA6RJAclK89evDQX5n\nR9ZD+Cq3CBMlttvSTCht0qQVlwycedH8iWyYgP/mF0W35BIn7NuuZwWhgR00n/VG\n4nbKPOzTWbsP45awcmivdrS74P6mL84WfkghipdmcoyVb1B8ZP4Y/Ke0RXOnLhNe\nCfrXXvuW+Pvg2RTfwRDtehGQPAgXbmLmz2ZkV69RGIr54HJv84NDbqZovRTMr7gL\n9k3ciCzXCiYQgM8yAyGHV0KEhFSQ1HV7gMnt9UmxbxBE2pGU7vu3CwjYga5DpwU7\nw5wu1TmM5KgZtZvuWOTDnqDLf0cKoIbW8FeeCOn24elcj32bnQDuF9DPey1mqcvT\n/yEo/Ushyz6CVYxN8DGgcy2M9JOsnmjDx02h6qgWGWDuKgb9jZrvRedpAQCeemEd\nfhEs6ihqVxRFl16HxC4EVijybhAL76SsM2nbtIqW1apBQJQpXWtQwwdvgTVpdEtE\nr4ArVJYX5LrswnWEQMOelugUG6S3ZjMfcyOa/O0364iY73vyVgaYK+2XtT2usMux\nVL469Kj5m13T6w==\n=Mjs/\n-----END PGP PUBLIC KEY BLOCK-----" > /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 && echo -e "[epel]\nname=Extra Packages for Enterprise Linux 9 - \$basearch\nmetalink=https://mirrors.fedoraproject.org/metalink?repo=epel-9&arch=\$basearch&infra=\$infra&content=\$contentdir\nenabled=1\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9" > /etc/yum.repos.d/epel.repo; fi'

# update the base image to allow forward-looking optimistic updates during the testing phase, with the added benefit of helping move closer to passing security scans.
# -- excludes ansible so it remains at 2.9 tag as shipped with the base image
# -- installs python3-passlib and python3-bcrypt for oauth-proxy interface
# -- cleans up the cached data from dnf to keep the image as small as possible
RUN dnf update -y --exclude=ansible* && dnf install -y python3-passlib python3-bcrypt && dnf clean all && rm -rf /var/cache/dnf

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

# switch back to user 1001 when running the base image (non-root)
USER 1001

# copy in required artifacts for the operator
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
