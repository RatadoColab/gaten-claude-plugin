# Python — Testes com pytest

Boas práticas para testes automatizados em Python 3.11+ com pytest.

---

## pytest vs unittest

| Característica | pytest | unittest |
|---|---|---|
| Sintaxe | `assert x == y` simples | `self.assertEqual(x, y)` verboso |
| Fixtures | Sistema declarativo e composável | `setUp`/`tearDown` por classe |
| Plugins | Ecossistema rico (`-cov`, `-mock`, `xdist`) | Limitado |
| Descoberta | Automática por convenção | Requer herança de `TestCase` |
| Parametrize | `@pytest.mark.parametrize` nativo | Requer `subTest` ou biblioteca |
| Saída | Relatório legível com diffs automáticos | Saída básica |

> Usar pytest para todo código novo. Manter unittest apenas em legado que já o usa.

---

## Estrutura de Testes

```
meu_projeto/
├── src/
│   └── meu_pacote/
│       ├── services.py
│       └── repositories.py
├── tests/
│   ├── conftest.py          # shared fixtures for all tests
│   ├── unit/
│   │   ├── test_services.py
│   │   └── test_models.py
│   └── integration/
│       └── test_repositories.py
└── pyproject.toml
```

Convenções de nomenclatura:
- Arquivos: `test_*.py` ou `*_test.py`
- Funções: `test_*`
- Classes: `Test*` (sem herança obrigatória)

---

## Fixtures

```python
import pytest
from unittest.mock import MagicMock

# Function scope (default): fresh instance for each test
@pytest.fixture
def user_service(mock_repository):
    from meu_pacote.services import UserService
    return UserService(repository=mock_repository)

# Module scope: created once per test module — use for expensive setup
@pytest.fixture(scope="module")
def db_connection():
    conn = create_test_db()
    yield conn          # yield: code after runs as teardown
    conn.close()

# Session scope: created once for the entire test run
@pytest.fixture(scope="session")
def app_config():
    return {"env": "test", "debug": True}

# Fixture with teardown via yield
@pytest.fixture
def temp_file(tmp_path):
    path = tmp_path / "test_data.csv"
    path.write_text("id,name\n1,Ana\n")
    yield path
    # cleanup runs after test — even if test fails
    path.unlink(missing_ok=True)

# Composed fixture: depends on another fixture
@pytest.fixture
def mock_repository():
    repo = MagicMock()
    repo.find_by_id.return_value = None  # sensible default
    return repo
```

---

## conftest.py — Fixtures Compartilhadas

```python
# tests/conftest.py — available to all tests without explicit import
import pytest
from meu_pacote.models import User

@pytest.fixture
def sample_user() -> User:
    return User(id=1, name="Test User", email="test@example.com", age=30)

@pytest.fixture
def sample_users() -> list[User]:
    return [
        User(id=i, name=f"User {i}", email=f"user{i}@example.com", age=20 + i)
        for i in range(1, 6)
    ]

# tests/unit/conftest.py — available only to tests in unit/
@pytest.fixture
def unit_config():
    return {"unit": True}
```

---

## Parametrize — Múltiplos Cenários

```python
import pytest

# Basic parametrize
@pytest.mark.parametrize("value,expected", [
    (0, "zero"),
    (1, "positive"),
    (-1, "negative"),
])
def test_classify(value: int, expected: str) -> None:
    assert classify(value) == expected

# Descriptive IDs
@pytest.mark.parametrize("email,valid", [
    ("user@example.com", True),
    ("invalid-email", False),
    ("@nodomain.com", False),
    ("user@.com", False),
], ids=["valid", "no-at-sign", "no-local", "no-domain"])
def test_email_validation(email: str, valid: bool) -> None:
    result = validate_email(email)
    assert result == valid

# Combining multiple parametrize decorators (cartesian product)
@pytest.mark.parametrize("method", ["GET", "POST"])
@pytest.mark.parametrize("status", [200, 404])
def test_response_handling(method: str, status: int) -> None:
    # runs 4 times: GET/200, GET/404, POST/200, POST/404
    ...

# Indirect parametrize: pass parameter to fixture
@pytest.fixture
def user_with_role(request):
    return User(id=1, name="Test", email="t@t.com", age=25, role=request.param)

@pytest.mark.parametrize("user_with_role", ["admin", "viewer"], indirect=True)
def test_permissions(user_with_role):
    ...
```

---

## Markers — Categorizar Testes

```python
import pytest

# Marking individual tests
@pytest.mark.slow
def test_full_pipeline():
    ...

@pytest.mark.integration
def test_save_to_database():
    ...

@pytest.mark.skip(reason="feature not implemented yet")
def test_future_feature():
    ...

@pytest.mark.skipif(sys.platform == "win32", reason="unix only")
def test_unix_paths():
    ...

@pytest.mark.xfail(reason="known bug #123", strict=True)
def test_known_bug():
    ...
```

Registrar markers em `pyproject.toml` para evitar warnings:

```toml
[tool.pytest.ini_options]
markers = [
    "slow: tests that take > 5 seconds",
    "integration: tests that require external services",
    "unit: isolated unit tests",
]
```

Executar por marker: `pytest -m "not slow"` ou `pytest -m integration`.

---

## Mocking

### unittest.mock

```python
from unittest.mock import Mock, MagicMock, patch, call

def test_send_email_called_once(user_service, mock_repository):
    # configure mock return value
    mock_repository.find_by_id.return_value = User(
        id=1, name="Ana", email="ana@example.com", age=25
    )

    user_service.notify_user(user_id=1, message="Hello")

    # assert the mock was called correctly
    mock_repository.find_by_id.assert_called_once_with(1)

def test_external_api_failure():
    # patch replaces the object for the duration of the test
    with patch("meu_pacote.services.httpx.post") as mock_post:
        mock_post.side_effect = httpx.ConnectError("connection refused")

        with pytest.raises(ServiceUnavailableError):
            notify_via_webhook("http://hook.example.com", {})

# MagicMock: supports magic methods (__len__, __iter__, etc.)
def test_repository_count():
    repo = MagicMock()
    repo.__len__.return_value = 5
    assert len(repo) == 5
```

### pytest-mock

```python
# mocker fixture: automatically cleans up patches after each test
def test_cache_used_on_second_call(mocker, user_service):
    mock_fetch = mocker.patch.object(
        user_service,
        "_fetch_from_db",
        return_value={"id": 1, "name": "Ana"},
    )

    user_service.get_user(1)
    user_service.get_user(1)   # second call — should use cache

    mock_fetch.assert_called_once()   # DB accessed only once

# Spy: wraps real method — records calls without replacing behavior
def test_logging_called(mocker, user_service):
    spy = mocker.spy(user_service, "log_access")
    user_service.get_user(1)
    spy.assert_called_once_with(user_id=1)
```

---

## Cobertura com pytest-cov

```bash
# Run tests with coverage
pytest --cov=src --cov-report=term-missing --cov-report=html

# Fail if coverage drops below threshold
pytest --cov=src --cov-fail-under=80
```

```toml
# pyproject.toml
[tool.coverage.run]
source = ["src"]
omit = ["src/**/migrations/*", "src/**/conftest.py"]

[tool.coverage.report]
show_missing = true
skip_covered = false
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
    "@abstractmethod",
]
```

---

## pyproject.toml — Configuração Completa

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = [
    "--strict-markers",      # fail on unknown markers
    "--strict-config",       # fail on unknown config keys
    "-ra",                   # show summary of all non-passed tests
]
markers = [
    "slow: tests that take > 5 seconds",
    "integration: require external services (db, http)",
    "unit: isolated, no I/O",
]
filterwarnings = [
    "error",                 # treat warnings as errors
    "ignore::DeprecationWarning:httpx",   # allow known deprecations
]
```

---

## Exemplo Completo — Test Suite de um Serviço

```python
# tests/unit/test_user_service.py
from __future__ import annotations

import pytest
from unittest.mock import MagicMock, call
from meu_pacote.services import UserService
from meu_pacote.models import User
from meu_pacote.exceptions import NotFoundError, DuplicateEmailError


@pytest.fixture
def mock_repo() -> MagicMock:
    repo = MagicMock()
    repo.find_by_id.return_value = None
    repo.find_by_email.return_value = None
    return repo


@pytest.fixture
def service(mock_repo: MagicMock) -> UserService:
    return UserService(repository=mock_repo)


@pytest.fixture
def existing_user() -> User:
    return User(id=1, name="Ana Lima", email="ana@example.com", age=30)


class TestCreateUser:
    def test_creates_user_with_valid_data(
        self, service: UserService, mock_repo: MagicMock
    ) -> None:
        # Arrange
        mock_repo.save.return_value = User(
            id=99, name="Carlos", email="carlos@example.com", age=25
        )

        # Act
        result = service.create_user(
            name="Carlos", email="carlos@example.com", age=25
        )

        # Assert
        assert result.id == 99
        assert result.email == "carlos@example.com"
        mock_repo.save.assert_called_once()

    def test_raises_when_email_already_exists(
        self, service: UserService, mock_repo: MagicMock, existing_user: User
    ) -> None:
        mock_repo.find_by_email.return_value = existing_user

        with pytest.raises(DuplicateEmailError, match="ana@example.com"):
            service.create_user(
                name="Outro", email="ana@example.com", age=20
            )

        mock_repo.save.assert_not_called()

    @pytest.mark.parametrize("age,error_fragment", [
        (-1, "age must be non-negative"),
        (151, "age must be <= 150"),
    ], ids=["negative", "too-large"])
    def test_rejects_invalid_age(
        self, service: UserService, age: int, error_fragment: str
    ) -> None:
        with pytest.raises(ValueError, match=error_fragment):
            service.create_user(name="Test", email="t@t.com", age=age)


class TestFindUser:
    def test_returns_user_when_found(
        self, service: UserService, mock_repo: MagicMock, existing_user: User
    ) -> None:
        mock_repo.find_by_id.return_value = existing_user

        result = service.get_user(user_id=1)

        assert result == existing_user
        mock_repo.find_by_id.assert_called_once_with(1)

    def test_raises_not_found_when_missing(
        self, service: UserService, mock_repo: MagicMock
    ) -> None:
        mock_repo.find_by_id.return_value = None

        with pytest.raises(NotFoundError, match="Usuário #99"):
            service.get_user(user_id=99)
```
