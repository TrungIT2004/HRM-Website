import { redirect } from 'next/navigation';

// ponytail: /tickets/manage không có trang riêng — vào là thấy Tổng quan luôn
export default function TicketManageIndex() {
  redirect('/tickets/manage/overview');
}
