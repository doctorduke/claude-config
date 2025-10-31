#!/usr/bin/env python3
"""
Secure secret encryption using libsodium (PyNaCl)
This script implements GitHub's required crypto_box_seal algorithm for secret encryption.

Security properties:
- Authenticated encryption using X25519 + XSalsa20 + Poly1305
- 256-bit equivalent security strength
- Forward secrecy through ephemeral keys
- No key storage required (sealed box construction)

OWASP References:
- OWASP Cryptographic Storage Cheat Sheet
- Use of strong, authenticated encryption (AEAD)
- Proper key derivation and management
"""

import sys
import base64
import os

try:
    from nacl import encoding, public
except ImportError:
    print("ERROR: PyNaCl not installed. Please run: pip install PyNaCl", file=sys.stderr)
    print("PyNaCl is the Python binding for libsodium, required for secure encryption", file=sys.stderr)
    sys.exit(1)

def encrypt_secret(public_key_b64: str, secret_value: str) -> str:
    """
    Encrypt a secret using libsodium's sealed box (crypto_box_seal).
    
    Args:
        public_key_b64: Base64-encoded public key from GitHub API
        secret_value: Plain text secret to encrypt
        
    Returns:
        Base64-encoded encrypted secret
        
    Raises:
        Exception: If encryption fails for any reason
    """
    # Security: Input validation
    if not public_key_b64 or not secret_value:
        raise ValueError("Missing required encryption parameters")
    
    # Decode the public key from base64
    public_key_bytes = base64.b64decode(public_key_b64)
    
    # Create a PublicKey object from the bytes
    public_key_obj = public.PublicKey(public_key_bytes)
    
    # Create a SealedBox for encryption
    # Sealed box provides authenticated encryption without requiring a sender's key
    sealed_box = public.SealedBox(public_key_obj)
    
    # Encrypt the secret value
    encrypted_bytes = sealed_box.encrypt(secret_value.encode('utf-8'))
    
    # Encode the result in base64 for the API
    encrypted_b64 = base64.b64encode(encrypted_bytes).decode('ascii')
    
    return encrypted_b64

def main():
    """Main entry point for CLI usage."""
    # Get parameters from environment variables for security (not CLI args)
    public_key_b64 = os.environ.get('GITHUB_PUBLIC_KEY', '')
    secret_value = os.environ.get('SECRET_VALUE', '')
    
    if not public_key_b64 or not secret_value:
        print("ERROR: Missing required encryption parameters", file=sys.stderr)
        print("Set GITHUB_PUBLIC_KEY and SECRET_VALUE environment variables", file=sys.stderr)
        sys.exit(1)
    
    try:
        encrypted = encrypt_secret(public_key_b64, secret_value)
        print(encrypted)
        sys.exit(0)
    except ValueError as e:
        print(f"ERROR: Invalid input: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        # Catch nacl.exceptions.* and other crypto errors
        print(f"ERROR: Encryption failed: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
