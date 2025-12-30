'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useParams } from 'next/navigation'

const catechismContent: { [key: string]: any } = {
    '1': {
        title: 'The Ten Commandments',
        titleHindi: 'दस आज्ञाएँ',
        sections: [
            {
                question: 'What is the First Commandment?',
                answer: 'You shall have no other gods.',
                explanation: 'We should fear, love, and trust in God above all things.'
            },
            {
                question: 'What is the Second Commandment?',
                answer: 'You shall not misuse the name of the Lord your God.',
                explanation: 'We should fear and love God so that we do not curse, swear, use satanic arts, lie, or deceive by His name, but call upon it in every trouble, pray, praise, and give thanks.'
            }
            // Add more commandments as needed
        ]
    },
    '2': {
        title: "The Apostles' Creed",
        titleHindi: 'प्रेरितों का विश्वास-कथन',
        sections: [
            {
                question: 'The First Article: Creation',
                answer: 'I believe in God, the Father Almighty, Maker of heaven and earth.',
                explanation: 'I believe that God has made me and all creatures; that He has given me my body and soul, eyes, ears, and all my members, my reason and all my senses, and still takes care of them.'
            }
            // Add more articles
        ]
    }
    // Add chapters 3-6
}

export default function CatechismChapterPage() {
    const params = useParams()
    const chapterId = params.id as string
    const chapter = catechismContent[chapterId]

    if (!chapter) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="text-center">
                    <h1 className="text-2xl font-bold mb-4">Chapter Not Found</h1>
                    <Link href="/pwa/catechism" className="text-blue-500 underline">
                        Back to Catechism
                    </Link>
                </div>
            </div>
        )
    }

    return (
        <div className="min-h-screen bg-gray-50 pb-20">
            {/* Header */}
            <header className="bg-white sticky top-0 z-50 shadow-sm p-4">
                <div className="flex items-center gap-3">
                    <Link href="/pwa/catechism" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                        ←
                    </Link>
                    <div>
                        <h1 className="text-xl font-bold">{chapter.title}</h1>
                        <p className="text-sm text-gray-600">{chapter.titleHindi}</p>
                    </div>
                </div>
            </header>

            {/* Content */}
            <div className="p-6 max-w-4xl mx-auto space-y-6">
                {chapter.sections.map((section: any, index: number) => (
                    <div key={index} className="bg-white rounded-2xl p-6 shadow-md">
                        <h2 className="text-lg font-bold text-purple-600 mb-3">
                            {section.question}
                        </h2>
                        <div className="bg-purple-50 rounded-xl p-4 mb-3">
                            <p className="font-semibold text-gray-800">{section.answer}</p>
                        </div>
                        <p className="text-gray-700 leading-relaxed">{section.explanation}</p>
                    </div>
                ))}
            </div>

            {/* Bottom Navigation */}
            <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-4">
                <div className="flex justify-between items-center max-w-4xl mx-auto">
                    <Link
                        href={`/pwa/catechism/${Math.max(1, parseInt(chapterId) - 1)}`}
                        className={`px-6 py-3 rounded-xl font-bold ${parseInt(chapterId) === 1
                                ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                                : 'bg-purple-500 text-white hover:bg-purple-600'
                            }`}
                    >
                        ← Previous
                    </Link>
                    <Link
                        href={`/pwa/catechism/${Math.min(6, parseInt(chapterId) + 1)}`}
                        className={`px-6 py-3 rounded-xl font-bold ${parseInt(chapterId) === 6
                                ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                                : 'bg-purple-500 text-white hover:bg-purple-600'
                            }`}
                    >
                        Next →
                    </Link>
                </div>
            </div>
        </div>
    )
}
