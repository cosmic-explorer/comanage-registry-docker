"""
Django backend that uses the RemoteUserBackend as a base
class and that sets the email field on the user model
to be the same as the username field each time a new
user is created.
"""

from django.contrib.auth.backends import RemoteUserBackend
from allauth.account.utils import sync_user_email_addresses
from allauth.account.models import EmailAddress

class MailHeaderBackend(RemoteUserBackend):
    def configure_user(self, user):
        username = user.get_username()
        user.email = username;
        sync_user_email_addresses(user)
        user.save()

        emails = EmailAddress.objects.filter(user=user, verified=False)
        for email in emails:
            email.verified=True
            email.save()

        return user
