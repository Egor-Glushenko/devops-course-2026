import re


def validate_email(email: str) -> bool:
    \"\"\"Проверяет корректность email.\"\"\"
    pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return bool(re.match(pattern, email))


def validate_snils(snils: str) -> bool:
    \"\"\"Проверяет СНИЛС (изменение преподавателя).\"\"\"
    pattern = r'^\d{3}-\d{3}-\d{3} \d{2}$'
    return bool(re.match(pattern, snils.strip()))
