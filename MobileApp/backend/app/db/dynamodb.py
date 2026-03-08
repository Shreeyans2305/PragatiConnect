import boto3
from typing import Optional, Dict, Any, List
from datetime import datetime
from app.config import settings


class DynamoDBClient:
    """Client for DynamoDB operations."""

    def __init__(self):
        self.client = boto3.client("dynamodb", region_name=settings.aws_region)
        self.resource = boto3.resource("dynamodb", region_name=settings.aws_region)

    # ─── User Operations ─────────────────────────────────────────────────────

    def get_user(self, email: str) -> Optional[Dict[str, Any]]:
        """Get user by email."""
        table = self.resource.Table(settings.dynamodb_table_users)
        response = table.get_item(Key={"email": email})
        return response.get("Item")

    def create_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new user."""
        table = self.resource.Table(settings.dynamodb_table_users)
        now = datetime.utcnow().isoformat()
        user_data["created_at"] = now
        user_data["updated_at"] = now
        table.put_item(Item=user_data)
        return user_data

    def update_user(self, email: str, updates: Dict[str, Any]) -> Dict[str, Any]:
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
            Key={"email": email},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_attr_names,
            ExpressionAttributeValues=expr_attr_values,
            ReturnValues="ALL_NEW",
        )
        return response.get("Attributes", {})

    def delete_user(self, email: str) -> bool:
        """Delete user."""
        table = self.resource.Table(settings.dynamodb_table_users)
        table.delete_item(Key={"email": email})
        return True

    # ─── Conversation Operations ─────────────────────────────────────────────

    def get_conversation(
        self, user_email: str, conversation_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get conversation by ID."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        response = table.get_item(
            Key={"user_email": user_email, "conversation_id": conversation_id}
        )
        return response.get("Item")

    def create_conversation(
        self, user_email: str, conversation_id: str, messages: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Create a new conversation."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        now = datetime.utcnow().isoformat()
        conversation = {
            "user_email": user_email,
            "conversation_id": conversation_id,
            "messages": messages,
            "created_at": now,
            "updated_at": now,
        }
        table.put_item(Item=conversation)
        return conversation

    def add_message_to_conversation(
        self, user_email: str, conversation_id: str, message: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Add a message to existing conversation."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        
        response = table.update_item(
            Key={"user_email": user_email, "conversation_id": conversation_id},
            UpdateExpression="SET messages = list_append(messages, :msg), updated_at = :now",
            ExpressionAttributeValues={
                ":msg": [message],
                ":now": datetime.utcnow().isoformat(),
            },
            ReturnValues="ALL_NEW",
        )
        return response.get("Attributes", {})

    def get_user_conversations(
        self, user_email: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get recent conversations for a user."""
        table = self.resource.Table(settings.dynamodb_table_conversations)
        
        response = table.query(
            KeyConditionExpression="user_email = :email",
            ExpressionAttributeValues={":email": user_email},
            ScanIndexForward=False,  # Most recent first
            Limit=limit,
        )
        return response.get("Items", [])

    # ─── Price Estimate Operations ───────────────────────────────────────────

    def create_price_estimate(
        self, user_email: str, estimate_id: str, estimate_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create a new price estimate record."""
        table = self.resource.Table(settings.dynamodb_table_estimates)
        now = datetime.utcnow().isoformat()
        estimate = {
            "user_email": user_email,
            "estimate_id": estimate_id,
            **estimate_data,
            "created_at": now,
        }
        table.put_item(Item=estimate)
        return estimate

    def get_user_estimates(
        self, user_email: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get recent price estimates for a user."""
        table = self.resource.Table(settings.dynamodb_table_estimates)
        
        response = table.query(
            KeyConditionExpression="user_email = :email",
            ExpressionAttributeValues={":email": user_email},
            ScanIndexForward=False,
            Limit=limit,
        )
        return response.get("Items", [])

    def get_estimate(
        self, user_email: str, estimate_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get specific price estimate."""
        table = self.resource.Table(settings.dynamodb_table_estimates)
        response = table.get_item(
            Key={"user_email": user_email, "estimate_id": estimate_id}
        )
        return response.get("Item")


# Singleton instance
dynamodb = DynamoDBClient()
