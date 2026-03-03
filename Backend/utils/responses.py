def success(data=None, message=None):
    response = {
        "status": "success"
    }

    if message:
        response["message"] = message

    if data is not None:
        response["data"] = data

    return response


def error(message, code=None):
    response = {
        "status": "error",
        "message": message
    }

    if code:
        response["code"] = code

    return response