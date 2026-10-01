from app.core.security import generate_token, hash_token


class AuthService:
    def issue_device_token(self) -> tuple[str, str]:
        token = generate_token()
        return token, hash_token(token)
