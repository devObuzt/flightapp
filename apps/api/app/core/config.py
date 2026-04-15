from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyHttpUrl
from typing import List


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ─── App ──────────────────────────────────────────────
    app_name: str = "CheckinCheckOut API"
    environment: str = "development"
    debug: bool = False

    # ─── Database ─────────────────────────────────────────
    database_url: str

    # ─── Redis ────────────────────────────────────────────
    redis_url: str = "redis://localhost:6379/0"

    # ─── JWT ──────────────────────────────────────────────
    jwt_secret_key: str
    jwt_refresh_secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    # ─── Encryption ───────────────────────────────────────
    encryption_key: str = ""  # AES-256 for passport / travel document fields

    # ─── CORS ─────────────────────────────────────────────
    cors_origins: str = "http://localhost:3000"

    @property
    def cors_origins_list(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",")]

    # ─── Anthropic ────────────────────────────────────────
    anthropic_api_key: str = ""

    # ─── Amadeus ──────────────────────────────────────────
    amadeus_client_id: str = ""
    amadeus_client_secret: str = ""
    amadeus_base_url: str = "https://test.api.amadeus.com"

    # ─── ALP (Flight Provider) ────────────────────────────
    alp_client_id: str = ""
    alp_client_secret: str = ""
    alp_token_url: str = "https://login.alp.co.il/auth/realms/ALP/protocol/openid-connect/token"
    alp_listener_url: str = "https://alp.co.il/Json/listener.php"
    alp_booking_url: str = "https://alp.co.il/newBooking"

    # ─── Kaspi Pay ────────────────────────────────────────
    kaspi_api_key: str = ""
    kaspi_webhook_secret: str = ""

    # ─── Stripe ───────────────────────────────────────────
    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""

    # ─── Twilio ───────────────────────────────────────────
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_phone_number: str = ""

    # ─── Deepgram ─────────────────────────────────────────
    deepgram_api_key: str = ""

    # ─── ElevenLabs ───────────────────────────────────────
    elevenlabs_api_key: str = ""

    # ─── AWS ──────────────────────────────────────────────
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    aws_region: str = "eu-west-1"

    # ─── Firebase ─────────────────────────────────────────
    firebase_service_account: str = ""

    # ─── Resend ───────────────────────────────────────────
    resend_api_key: str = ""

    # ─── Cloudflare R2 ────────────────────────────────────
    cloudflare_r2_access_key: str = ""
    cloudflare_r2_secret_key: str = ""
    cloudflare_r2_bucket: str = "checkincheckout"
    cloudflare_r2_endpoint: str = ""


settings = Settings()
