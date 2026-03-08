import boto3
from typing import Optional
import uuid
from app.config import settings


class S3Client:
    """Client for S3 operations."""

    def __init__(self):
        import boto3 as _boto3
        region = settings.aws_s3_region
        self.client = _boto3.client(
            "s3",
            region_name=region,
            config=_boto3.session.Config(
                s3={"addressing_style": "virtual"},
                signature_version="s3v4",
            ),
        )
        self.bucket = settings.s3_bucket_images

    def upload_image(
        self,
        image_bytes: bytes,
        user_identifier: str,
        content_type: str = "image/jpeg",
    ) -> str:
        """Upload image and return the S3 key."""
        # Generate unique key
        image_id = str(uuid.uuid4())
        # Sanitize identifier (email / phone) for path
        safe_identifier = (
            user_identifier
            .replace("+", "")
            .replace("@", "_")
            .replace(".", "_")
            .replace(" ", "")
            .replace("/", "_")
        )
        key = f"images/{safe_identifier}/{image_id}.jpg"

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
