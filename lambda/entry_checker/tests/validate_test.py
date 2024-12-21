from entry_checker.validate import validate_sender

import pytest

allowed_senders_regex = ".*@example.com"


@pytest.mark.parametrize("sender", ["test@example.com", "<test@example.com>"])
def test_validate_sender_success(sender):
    assert validate_sender(allowed_senders_regex, sender)


@pytest.mark.parametrize(
    "sender", ["test@different-domain.com", "<test@different-domain.com>"]
)
def test_validate_sender_fail(sender):
    assert not validate_sender(allowed_senders_regex, sender)
