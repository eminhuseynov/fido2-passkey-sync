# fido2-passkey-sync
A Simple PowerShell + fido2-manage Trick
So, like many of you probably, I've got multiple FIDO2.1 security keys - a main one that I carry around everywhere, and a couple of backups hidden away in drawers and bags in case I lose or damage the primary. These days, with more and more services supporting discoverable credentials (a.k.a. passkeys stored directly on the key), it's super important to keep all your keys in sync - otherwise, you could get locked out of an account just because you forgot to register the backup.
But how do you actually check what's stored on each key? That's where this project comes in.
