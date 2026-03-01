import boto3
from typing import Optional, Dict, Any, List
from datetime import datetime
from app.config import settings


class DynamoDBClient:
    """Client for DynamoDB operations."""

    def __init__(self):
        self.client = boto3.client(
            "dynamodb",
            region_name=settings.aws_region,
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
        )
        self.resource = boto3.resource(
            "dynamodb",
            region_name=settings.aws_region,
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
        )

    # ─── User Operations ─────────────────────────────────────────────────────

    def get_user(self, phone_number: str) -> Optional[Dict[str, Any]]:
        """Get user by phone number."""
        table = self.resource.Table(settings.dynamodb_table_users)
        response = table.get_item(Key={"phone_number": phone_number})
        return response.get("Item")

    def create_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new user."""
        table = self.resource.Table(settings.dynamodb_table_users)
        now = datetime.utcnow().isoformat()
        user_data["created_at"] = now
        user_data["updated_at"] = now
        table.put_item(Item=user_data)
        return user_data

    def update_user(self, phone_number: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """Update user profile."""
        table = self.resource.Table(settings.dynamodb_table_users)
        
        # Build update expression
        update_expr_parts = []
        expr_attr_values = {}
        expr_attr_names = {}
        
        for key, value in updates.items():
            if value is not None:
                safe_key = f"#{key}"
                expr_attr_names[safe_key] = key
                expr_attr_values[f":{key}"] = value
                update_expr_parts.append(f"{safe_key} = :{key}")
        
        # Always update updated_at
        expr_attr_names["#updated_at"] = "updated_at"
        expr_attr_values[":updated_at"] = datetime.utcnow().isoformat()
        update_expr_parts.append("#updated_at = :updated_at")
        
        update_expr = "SET " + ", ".join(update_expr_parts)
        
        response = table.update_item(
            Key={"phone_number": phone_number},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_values,
            ReturnValues="ALL_NEW",
        )
        return response.get("Attributes", {})

    def delete_user(self, phone_number: str) -> bool:
        """Delete user."""
        table = self.resource.Table(settings.dynamodb_table_users)
        table.delete_item(Key={"phone_number": phone_number})
        return True

    # ─── Conversation Operations ─────────────────────────────────────────────

    def get_conversation(
        self, user_phone: str, conversation_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get conversation by ID."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        response = table.get_item(
            Key={"user_phone": user_phone, "conversation_id": conversation_id}
        )
        return response.get("Item")

    def create_conversation(
        self, user_phone: str, conversation_id: str, messages: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Create a new conversation."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        now = datetime.utcnow().isoformat()
        conversation = {
            "user_phone": user_phone,
            "conversation_id": conversation_id,
            "messages": messages,
            "created_at": now,
            "updated_at": now,
        }
        table.put_item(Item=conversation)
        return conversation

    def add_message_to_conversation(
        self, user_phone: str, conversation_id: str, message: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Add a message to existing conversation."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        
        response = table.update_item(
            Key={"user_phone": user_phone, "conversation_id": conversation_id},
            UpdateExpression="SET messages = list_append(messages, :msg), updated_at = :now",
            ExpressionAttributeValues={
                ":msg": [message],
                ":now": datetime.utcnow().isoformat(),
            },
            ReturnValues="ALL_NEW",
        )
        return response.get("Attributes", {})

    def get_user_conversations(
        self, user_phone: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get recent conversations for a user."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        
        response = table.query(
            KeyConditionExpression="user_phone = :phone",
            ExpressionAttributeValues={":phone": user_phone},
            ScanIndexForward=False,  # Most recent first
            Limit=limit,
        )
        return response.get("Items", [])

    # ─── Price Estimate Operations ───────────────────────────────────────────

    def create_price_estimate(
        self, user_phone: str, estimate_id: str, estimate_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create a new price estimate record."""
        table = self.resource.Table(settings.dynamodb_table_estimates)
        now = datetime.utcnow().isoformat()
        estimate = {
            "user_phone": user_phone,
            "estimate_id": estimate_id,
            **estimate_data,
            "created_at": now,
        }
        table.put_item(Item=estimate)
        return estimate

    def get_user_estimates(
        self, user_phone: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get recent price estimates for a user."""
        table = self.resource.Table(settings.dynamodb_table_estimates)
        
        response = table.query(
            KeyConditionExpression="user_phone = :phone",
            ExpressionAttributeValues={":phone": user_phone},
            ScanIndexForward=False,
            Limit=limit,
        )
        return response.get("Items", [])

    def get_estimate(
        self, user_phone: str, estimate_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get specific price estimate."""
        table = self.resource.Table(settings.dynamodb_table_estimates)
        response = table.get_item(
            Key={"user_phone": user_phone, "estimate_id": estimate_id}
        )
        return response.get("Item")


# Singleton instance
dynamodb = DynamoDBClient()
