import boto3
from typing import Optional
import uuid
from app.config import settings


class S3Client:
    """Client for S3 operations."""

    def __init__(self):
        self.client = boto3.client(
            "s3",
            region_name=settings.aws_region,
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
        )
        self.bucket = settings.s3_bucket_images

    def upload_image(
        self,
        image_bytes: bytes,
        user_phone: str,
        content_type: str = "image/jpeg",
    ) -> str:
        """Upload image and return the S3 key."""
        # Generate unique key
        image_id = str(uuid.uuid4())
        # Sanitize phone number for path
        phone_safe = user_phone.replace("+", "").replace(" ", "")
        key = f"images/{phone_safe}/{image_id}.jpg"

        self.client.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=image_bytes,
            ContentType=content_type,
        )
        return key

    def get_presigned_url(self, key: str, expires_in: int = 3600) -> str:
        """Get a presigned URL for an image."""
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.bucket, "Key": key},
            ExpiresIn=expires_in,
        )

    def delete_image(self, key: str) -> bool:
        """Delete an image from S3."""
        self.client.delete_object(Bucket=self.bucket, Key=key)
        return True


# Singleton instance
s3_client = S3Client()
