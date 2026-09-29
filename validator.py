import re


def validate_email(email: str) -> bool:
    """Проверяет корректность email."""
    pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return bool(re.match(pattern, email))


def validate_phone(phone: str) -> bool:
    """Проверяет российский номер телефона."""
    pattern = r'^(\+7|8)[\s\-\(\)]*\d{3}[\s\-\)]*\d{3}[\s\-]*\d{2}[\s\-]*\d{2}$'
    return bool(re.match(pattern, phone.strip()))


def validate_snils(snils: str) -> bool:
    """Проверяет СНИЛС (изменение преподавателя)."""
    pattern = r'^\d{3}-\d{3}-\d{3} \d{2}$'
    return bool(re.match(pattern, snils.strip()))