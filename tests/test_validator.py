from validator import validate_email, validate_phone


def test_validate_email():
    assert validate_email('test@example.com') is True
    assert validate_email('invalid-email') is False


def test_validate_phone():
    assert validate_phone('+79991234567') is True
    assert validate_phone('89991234567') is True
    assert validate_phone('+7 (999) 123-45-67') is True
    assert validate_phone('12345') is False
