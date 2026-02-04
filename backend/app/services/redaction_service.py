import re

class RedactionService:
    @staticmethod
    def redact_pii(text: str) -> str:
        """
        Redacts PII (Aadhaar, PAN, Phone, Email) from the given text.
        """
        if not text:
            return text
            
        # 1. Redact Aadhaar Numbers (12-digit sequences)
        # Matches 12 digits, possibly with spaces or hyphens every 4 digits
        aadhaar_pattern = r'\b\d{4}[ -]?\d{4}[ -]?\d{4}\b'
        text = re.sub(aadhaar_pattern, '[AADHAAR_REDACTED]', text)
        
        # 2. Redact PAN Numbers (10-character format: 5 letters, 4 digits, 1 letter)
        pan_pattern = r'\b[A-Z]{5}[0-9]{4}[A-Z]{1}\b'
        text = re.sub(pan_pattern, '[PAN_REDACTED]', text, flags=re.IGNORECASE)
        
        # 3. Redact Mobile Numbers (10-digit Indian numbers, optional +91 or 0 prefix)
        # Simplified pattern for common Indian mobile formats
        phone_pattern = r'\b(?:\+91|0)?[6-9]\d{9}\b'
        text = re.sub(phone_pattern, '[PHONE_REDACTED]', text)
        
        # 4. Redact Emails
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        text = re.sub(email_pattern, '[EMAIL_REDACTED]', text)
        
        return text
