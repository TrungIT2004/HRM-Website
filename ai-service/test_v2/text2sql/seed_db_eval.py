"""Seed data Jan-Sep 2026 cho user test DB_ONLY retrieval (module moi).

User: Dang Thanh Khai (d47d452a...), joined 2026-01-02.
Seed: asset_assignments (3), asset_requests (3), it_tickets (5).
Performance da co san 8 reviews + 80 scores -> khong seed.

Chay:  python tests/retrieval_db_only/seed_db_eval.py          # seed
        python tests/retrieval_db_only/seed_db_eval.py --cleanup  # xoa seed + tra status assets
"""
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"
DEPT = "0190abcd-1234-7def-89ab-cdef01234567"
LT_CAT = "c0a80106-a105-116d-81a1-05517c070000"   # Laptop
MN_CAT = "c0a80106-a105-116d-81a1-05517c2a0003"   # Man hinh
PH_CAT = "c0a80106-a105-116d-81a1-05517c270002"   # Dien thoai
LT_ASSET = "23c77fa6-6d6b-484a-804b-b43ca73cbb6e"  # LT-0004 ThinkPad T14
MN_ASSET = "82230fc1-91e8-49b2-b712-f4879620099a"  # MN-0002 LG 4K
PK_ASSET = "7b9f7f63-9284-41e5-a7f9-5ec35de459b7"  # PK-0001 Keychron
MARK = "SEED-EVAL"

ASSIGNMENTS = [
    # (aid, asset, assigned, returned, exp_ret, status, notes, cond_assign, cond_return)
    ("11111111-1111-4111-8111-111111111111", LT_ASSET, "2026-02-10 09:00:00",
     None, None, "active", "Cap moi khi onboarding", "Moi 100%", None),
    ("22222222-2222-4222-8222-222222222222", MN_ASSET, "2026-03-05 09:00:00",
     None, None, "active", "Bo sung man hinh phu", "Moi 100%", None),
    ("33333333-3333-4333-8333-333333333333", PK_ASSET, "2026-02-10 09:00:00",
     "2026-06-20 17:00:00", None, "returned", "Doi sang ban phim khac",
     "Tot", "Tot, pin yeu"),
]

REQUESTS = [
    # (rid, cat, reason, needed, exp_ret, status, rejection)
    ("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", LT_CAT, "Can laptop de lam viec",
     "2026-01-15", "2026-01-20", "approved", None, "35337165-e0d0-4dd1-9c67-cc48180363af"),
    ("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", PH_CAT, "Can dien thoai cong viec",
     "2026-05-10", None, "rejected", "Vuot dinh muc cap phat", None),
    ("cccccccc-cccc-4ccc-8ccc-cccccccccccc", MN_CAT, "Xin them man hinh 4K lam viec",
     "2026-08-12", "2026-09-01", "pending", None, None),
]

TICKETS = [
    # mang OPEN HIGH (thang 9)
    ("d0000000-0000-4000-8000-000000000001", "Mang cham, rot mang lien tuc",
     "NETWORK", "Mang phong ky thuat cham tu sang, anh huong hop online",
     "Tang 3", "HIGH", "2026-09-10 08:30:00", "OPEN", None, None),
    # may in IN_PROGRESS (thang 8)
    ("d0000000-0000-4000-8000-000000000002", "May in HP LaserJet 404dn",
     "PRINTER", "May in ket giay lien tuc, muc con 20%",
     "Tang 3", "NORMAL", "2026-08-15 14:00:00", "IN_PROGRESS", None, None),
    # laptop DONE (thang 7)
    ("d0000000-0000-4000-8000-000000000003", "ThinkPad T14 Gen 4",
     "LAPTOP_PC", "Pin chai nhanh, sac day chi dung duoc 1 gio",
     "Tang 3", "NORMAL", "2026-07-08 09:00:00", "DONE",
     "Da thay pin moi, test on dinh", "2026-07-09 16:00:00"),
    # phan mem DONE (thang 3)
    ("d0000000-0000-4000-8000-000000000004", "Office 365",
     "SOFTWARE", "Khong dang nhap duoc Outlook, bao loi license",
     "Tang 3", "NORMAL", "2026-03-12 10:00:00", "DONE",
     "Reset license, dang nhap lai OK", "2026-03-12 15:00:00"),
    # email DONE (thang 6)
    ("d0000000-0000-4000-8000-000000000005", "Email cong ty",
     "ACCOUNT_EMAIL", "Quen mat khau email, can reset gap",
     "Tang 3", "NORMAL", "2026-06-05 08:00:00", "DONE",
     "Da reset va cap mat khau moi", "2026-06-05 09:30:00"),
]


def main() -> None:
    # ponytail: seed can quyen ghi; role hrm_ai_reader la readonly nen dung
    # superuser truc tiep. Chi dung cho test, khong dung o production code.
    import psycopg2

    cleanup = "--cleanup" in sys.argv
    conn = psycopg2.connect(
        "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm")
    cur = conn.cursor()
    try:
        if cleanup:
            cur.execute("DELETE FROM asset_assignments WHERE notes LIKE %s",
                        (f"%[{MARK}]%",))
            cur.execute("DELETE FROM asset_requests WHERE reason LIKE %s",
                        (f"%[{MARK}]%",))
            cur.execute("DELETE FROM it_tickets WHERE description LIKE %s",
                        (f"%[{MARK}]%",))
            cur.execute("UPDATE assets SET status='available' WHERE asset_id IN %s",
                        ((LT_ASSET, MN_ASSET, PK_ASSET),))
            conn.commit()
            print("cleaned seed rows, assets back to available")
            return

        for aid, asset, assigned, returned, exp_ret, st, notes, cond_a, cond_r in ASSIGNMENTS:
            cur.execute(
                # ponytail: chk_assignment_target bat buoc user XOR department
                # -> seed ca nhan de department_id NULL.
                """INSERT INTO asset_assignments
                   (assignment_id, asset_id, user_id, department_id, assigned_at,
                    returned_at, expected_return_date, status, notes,
                    condition_on_assign, condition_on_return, assigned_by, created_at)
                   VALUES (%s,%s,%s,NULL,%s,%s,%s,%s,%s,%s,%s,%s,NOW())
                   ON CONFLICT (assignment_id) DO NOTHING""",
                (aid, asset, UID, assigned, returned, exp_ret, st,
                 f"[{MARK}] {notes}", cond_a, cond_r, UID))
        for rid, cat, reason, needed, exp_ret, st, rej, approver in REQUESTS:
            cur.execute(
                """INSERT INTO asset_requests
                   (request_id, requestor_id, category_id, reason, needed_by_date,
                    expected_return_date, status, rejection_reason, approver_id,
                    created_at, updated_at)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,NOW(),NOW())
                   ON CONFLICT (request_id) DO NOTHING""",
                (rid, UID, cat, f"[{MARK}] {reason}", needed, exp_ret, st, rej,
                 approver))
        for tid, dev, cat, desc, loc, pri, created, st, note, resolved in TICKETS:
            cur.execute(
                """INSERT INTO it_tickets
                   (ticket_id, device_info, category, description, location,
                    priority, reporter_id, status, resolve_note, resolved_at,
                    created_at, updated_at)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                   ON CONFLICT (ticket_id) DO NOTHING""",
                (tid, dev, cat, f"[{MARK}] {desc}", loc, pri, UID, st,
                 note, resolved, created, created))
        cur.execute("UPDATE assets SET status='assigned' WHERE asset_id IN %s",
                    ((LT_ASSET, MN_ASSET),))
        conn.commit()
        print("seeded: 3 assignments, 3 requests, 5 tickets")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
