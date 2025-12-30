'use client'

import { useEffect } from 'react'

export default function PWASongsPage() {
    useEffect(() => {
        // Redirect to working HTML version
        window.location.href = '/pwa/index.html'
    }, [])

    return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
            <p>Redirecting to Sakshi Vani...</p>
        </div>
    )
}
