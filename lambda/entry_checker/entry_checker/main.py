import logging
import os
from entry_checker.validate import validate_sender

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def main(event, context):
    allowed_senders_regex = os.environ["ALLOWED_SENDERS_REGEX"]

    ses_notification = event["Records"].pop()["ses"]
    receipt = ses_notification["receipt"]

    logger.debug(receipt)

    stop_email = False

    if receipt["spfVerdict"]["status"] == "FAIL":
        logger.debug("SPF FAIL detected, cutting off")
        stop_email = True

    elif receipt["dkimVerdict"]["status"] == "FAIL":
        logger.debug("DKIM FAIL detected, cutting off")
        stop_email = True

    elif receipt["spamVerdict"]["status"] == "FAIL":
        logger.debug("SPAM FAIL detected, cutting off")
        stop_email = True

    elif receipt["virusVerdict"]["status"] == "FAIL":
        logger.debug("VIRUS FAIL detected, cutting off")
        stop_email = True

    else:
        # Such validation is not perfect, but paired with the above conditions
        # that rely on Amazon checks, it's definitely better than nothing.
        sender = ses_notification["mail"]["commonHeaders"]["from"].pop()

        if not validate_sender(allowed_senders_regex, sender):
            logger.debug("sender validation FAIL detected, cutting off")
            stop_email = True

    if stop_email:
        return {"disposition": "STOP_RULE_SET"}
