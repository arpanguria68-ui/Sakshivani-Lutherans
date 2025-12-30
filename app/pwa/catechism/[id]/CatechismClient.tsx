'use client'

import { useState } from 'react'
import Link from 'next/link'
import AccessibleReader from '@/app/components/AccessibleReader'

interface Section {
    question: string
    answer: string
    explanation: string
}

interface ChapterData {
    id: number
    title: string
    titleHindi: string
    intro: string
    sections: Section[]
    conclusion?: string
    nextChapter?: { id: number, title: string }
}

export default function CatechismClient({ chapter }: { chapter: ChapterData }) {
    const [activeIndex, setActiveIndex] = useState<number | null>(null)

    const toggleAccordion = (index: number) => {
        setActiveIndex(activeIndex === index ? null : index)
    }

    return (
        <>
            <style jsx global>{`
        @import url('/shared/theme.css');
        @import url('/pwa/catechism/catechism-ui.css');
      `}</style>

            <div className="min-h-screen pb-36">
                {/* Header */}
                <header style={{
                    background: 'rgba(255, 255, 255, 0.8)',
                    backdropFilter: 'blur(10px)',
                    padding: '1rem 1.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    borderBottom: '1px solid rgba(0, 0, 0, 0.05)',
                    position: 'sticky',
                    top: 0,
                    zIndex: 50
                }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <Link href="/pwa/catechism" className="back-link">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <line x1="19" y1="12" x2="5" y2="12"></line>
                                <polyline points="12 19 5 12 12 5"></polyline>
                            </svg>
                        </Link>
                        <h1 style={{ margin: 0, fontSize: '1.2rem' }}>{chapter.id}. {chapter.titleHindi}</h1>
                    </div>
                    <button style={{ background: 'transparent', border: 'none', fontSize: '1.2rem' }}>
                        🌙
                    </button>
                </header>

                <div className="container" id="catechism-content" style={{ padding: '20px' }}>
                    {/* Introduction Card */}
                    <div className="intro-card">
                        <div className="intro-label">परिचय (INTRODUCTION)</div>
                        <div className="intro-text">{chapter.intro}</div>
                    </div>

                    {/* Accordion List */}
                    <div className="accordion-list">
                        {chapter.sections.map((section, index) => (
                            <div
                                key={index}
                                className={`accordion-item ${activeIndex === index ? 'active' : ''}`}
                                onClick={() => toggleAccordion(index)}
                            >
                                <div className="accordion-header">
                                    <div className="badge">{index + 1}</div>
                                    <div className="header-text">
                                        <span className="sub-label">{section.question.split(' - ')[0]}</span>
                                        <span className="main-title">{section.question.split(' - ')[1] || section.question}</span>
                                    </div>
                                    <span className="chevron">▼</span>
                                </div>
                                <div className="accordion-content">
                                    <div className="content-inner">
                                        <p className="standout-text"><strong>{section.answer}</strong></p>
                                        <div className="question">इसका क्या अर्थ है?</div>
                                        <p>{section.explanation}</p>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* TTS Component */}
                <AccessibleReader contentId="catechism-content" />

                {/* Bottom Player */}
                {chapter.nextChapter && (
                    <div className="bottom-player" style={{
                        position: 'fixed',
                        bottom: 0,
                        left: 0,
                        right: 0,
                        background: '#0F1419',
                        padding: '16px 20px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        zIndex: 1000
                    }}>
                        <div className="next-chapter">
                            <span className="next-label" style={{ fontSize: '0.7rem', color: 'rgba(255,255,255,0.5)' }}>
                                NEXT CHAPTER
                            </span>
                            <Link href={`/pwa/catechism/${chapter.nextChapter.id}`} className="next-title" style={{
                                fontSize: '0.95rem',
                                color: 'white',
                                textDecoration: 'none'
                            }}>
                                {chapter.nextChapter.title}
                            </Link>
                        </div>
                    </div>
                )}
            </div>
        </>
    )
}
