import os
from dotenv import load_dotenv
import psycopg2
from psycopg2.pool import ThreadedConnectionPool
from pgvector.psycopg2 import register_vector

load_dotenv()

# ponytail: psycopg2 connection la object C — gan `conn.close = ...` nhu cu se AttributeError.
# Subclass + connection_factory giu nguyen API `conn.close()` tra ve pool cho 50+ call site.
class _PooledConnection(psycopg2.extensions.connection):
    def close(self):
        # Pool day (free >= minconn) thi putconn goi nguoc conn.close():
        # co nay de lan goi noi bo dong that thay vi de quy + deadlock lock.
        if getattr(self, '_returning', False):
            super().close()
            return
        pool = getattr(self, '_hrm_pool', None)
        if pool is None:
            super().close()
            return
        self._returning = True
        try:
            try:
                self.rollback()
            except Exception:
                pass
            if self.closed:
                super().close()
            else:
                pool.putconn(self)
        except Exception:
            try:
                super().close()
            except Exception:
                pass
        finally:
            self._returning = False


def _real_close(conn):
    psycopg2.extensions.connection.close(conn)


# ponytail: 1 pool/process, ceiling ~20 conn đồng thời (DB_POOL_MAX). Vượt thì lắp pgBouncer thay vì tăng max.
_pools = {}


def _pool(key, dsn):
    pool = _pools.get(key)
    if pool is None:
        pool = ThreadedConnectionPool(
            int(os.getenv("DB_POOL_MIN", "1")),
            int(os.getenv("DB_POOL_MAX", "20")), dsn,
            connection_factory=_PooledConnection)
        _pools[key] = pool
    return pool


def _checkout(pool, with_vector=False):
    conn = pool.getconn()
    try:
        if conn.closed:
            _real_close(conn)
            conn = pool.getconn()
        if with_vector:
            register_vector(conn)
    except Exception:
        try:
            _real_close(conn)
        except Exception:
            pass
        raise
    conn._hrm_pool = pool
    return conn


def get_db_connection():
    """Pooled connection tới PostgreSQL + pgvector. API giữ nguyên: `conn.close()` trả về pool."""
    db_url = os.getenv("DATABASE_URL", "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm_ai")
    return _checkout(_pool("ai", db_url), with_vector=True)


def get_hrm_connection():
    """Pooled readonly connection tới DB nghiệp vụ `hrm` cho Text-to-SQL.

    Dùng role hrm_ai_reader (xem sql/readonly_role.sql), không đăng ký
    pgvector vì DB này không có extension vector.
    """
    hrm_url = os.getenv(
        "HRM_DATABASE_URL",
        "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm")
    return _checkout(_pool("hrm", hrm_url))


def close_all():
    """Đóng hết pool (shutdown/test)."""
    for pool in _pools.values():
        pool.closeall()
    _pools.clear()
