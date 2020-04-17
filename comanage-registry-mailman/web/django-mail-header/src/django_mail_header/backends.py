"""
Django backend that uses the RemoteUserBackend as a base
class and that sets the email field on the user model
to be the same as the username field each time a new
user is created.
"""

from django.contrib.auth.backends import RemoteUserBackend
from allauth.account.utils import sync_user_email_addresses

class MailHeaderBackend(RemoteUserBackend):
    def configure_user(self, user):
        username = user.get_username()
        user.email = username;
        sync_user_email_addresses(user)
        user.save()

        return user
