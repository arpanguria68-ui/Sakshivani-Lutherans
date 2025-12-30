'use client'

import { useEffect } from 'react'

export default function BibleReaderPage() {
    useEffect(() => {
        // Redirect to working HTML version
        window.location.href = '/dashboard-web/read_bible.html'
    }, [])

    return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
            <p>Redirecting to Bible Reader...</p>
        </div>
    )
}
