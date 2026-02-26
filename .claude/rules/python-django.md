---
paths:
  - "**/django*/**"
  - "**/views/**/*.py"
  - "**/models/**/*.py"
  - "**/serializers/**/*.py"
  - "**/urls/**/*.py"
---
When working with Django/DRF code:
- Use class-based views (APIView, ViewSet) over function-based views
- Use Django REST Framework serializers for validation
- Follow Django's MVT pattern
- Use Django ORM queryset methods (select_related, prefetch_related)
- Use Django migrations for all schema changes
- Use Django signals sparingly — prefer explicit method calls
