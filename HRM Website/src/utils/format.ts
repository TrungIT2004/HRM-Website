// ponytail: pure string split, no `new Date()` (UTC-midnight parse shifts day in +07). Upgrade to Intl only if timezones needed.
/** 'YYYY-MM-DD' | ISO datetime -> 'DD/MM/YYYY' (+ ' HH:mm' if time present). DB format in, VN format out. */
export const formatDateVN = (v?: string | null): string => {
  if (!v) return '';
  const [d, t] = String(v).replace('T', ' ').split(' ');
  const p = d.split('-');
  if (p.length !== 3) return String(v);
  const base = `${p[2]}/${p[1]}/${p[0]}`;
  return t ? `${base} ${t.slice(0, 5)}` : base;
};
