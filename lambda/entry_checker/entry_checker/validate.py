import re


def validate_sender(allowed_senders_regex: str, sender: str):
    # Get rid of the "quotation marks"
    sender = sender.replace("<", "").replace(">", "")

    if re.search(allowed_senders_regex, sender):
        return True

    return False
