MIN_TEMP = 30
MAX_TEMP = 80


def validate_temperature(temp):
    if temp is None:
        return False, "Temperature is required"

    # Allow numeric strings like "60"
    try:
        temp = float(temp)
    except (ValueError, TypeError):
        return False, "Temperature must be a number"

    if temp < MIN_TEMP or temp > MAX_TEMP:
        return False, f"Temperature must be between {MIN_TEMP} and {MAX_TEMP}"

    return True, None