from typing import List, Dict
import re

class ComplianceService:
    def __init__(self):
        # Define risky patterns based on project requirements (fraud, theft, unilateral terms)
        self.risk_patterns = {
            'high-risk': [
                'unilateral termination', 'indemnify', 'indemnity', 'arbitration in foreign',
                'no refund', 'forfeit', 'waive rights', 'fraud', 'theft', 'penalty',
                'without liability', 'sole discretion'
            ],
            'flagged': [
                'jurisdiction', 'confidentiality', 'exclusivity', 'non-compete',
                'auto-renewal', 'termination for convenience', 'governing law'
            ]
        }

    def analyze_clauses(self, text: str) -> List[Dict[str, str]]:
        """Analyze text for risky clauses using keyword matching."""
        if not text:
            return []
            
        # Robust clause splitting
        candidates = re.split(r"\n+|;|(?<=\))\s*|\d+\.\s+", text)
        out = []

        for c in candidates:
            s = c.strip()
            if not s or len(s) < 10:
                continue
                
            lower_text = s.lower()
            status = 'ok'
            
            # Check for high risk
            for pattern in self.risk_patterns['high-risk']:
                if pattern in lower_text:
                    status = 'high-risk'
                    break
            
            # Check for flagged
            if status == 'ok':
                for pattern in self.risk_patterns['flagged']:
                    if pattern in lower_text:
                        status = 'flagged'
                        break
            
            out.append({'clause': s, 'status': status})
                
        if not out:
             return [{'clause': text[:200], 'status': 'ok'}]
             
        return out

# Singleton instance
compliance_service = ComplianceService()
