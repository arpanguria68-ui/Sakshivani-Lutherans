'use client'

import { useEffect } from 'react'

export default function CatechismChapterPage({ params }: { params: { id: string } }) {
    useEffect(() => {
        // Redirect to working HTML version based on chapter ID
        const chapterMap: { [key: string]: string } = {
            '1': '1-commandments',
            '2': '2-creed',
            '3': '3-prayer',
            '4': '4-baptism',
            '5': '5-communion',
            '6': '6-confession'
        }

        const fileName = chapterMap[params.id] || '1-commandments'
        window.location.href = `/pwa/catechism/${fileName}.html`
    }, [params.id])

    return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
            <p>Redirecting to Catechism Chapter...</p>
        </div>
    )
}

// Removed generateStaticParams - not compatible with 'use client'
