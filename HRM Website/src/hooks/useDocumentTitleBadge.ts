import { useEffect } from 'react';

export function useDocumentTitleBadge(unreadCount: number) {
  useEffect(() => {
    const originalTitle = document.title;

    const updateTitle = () => {
      if (unreadCount > 0 && (document.hidden || !document.hasFocus())) {
        document.title = `(${unreadCount}) ${originalTitle}`;
      } else {
        document.title = originalTitle;
      }
    };

    // Initial update
    updateTitle();

    // Update on visibility/focus changes
    const handleVisibilityChange = () => updateTitle();
    const handleFocus = () => updateTitle();
    const handleBlur = () => updateTitle();

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', handleFocus);
    window.addEventListener('blur', handleBlur);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('blur', handleBlur);
      // Restore original title on cleanup
      document.title = originalTitle;
    };
  }, [unreadCount]);
}