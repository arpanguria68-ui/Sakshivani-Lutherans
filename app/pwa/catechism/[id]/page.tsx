'use client'

import { useState } from 'react'
import Link from 'next/link'

interface CommandmentSection {
    question: string
    answer: string
    explanation: string
}

const commandmentsData: CommandmentSection[] = [
    {
        question: 'पहली आज्ञा - परमेश्वर तेरा ईश्वर मैं हूँ',
        answer: 'तू किसी दूसरे को ईश्वर मत मानना।',
        explanation: 'हम सब वस्तुओं से अधिक ईश्वर का भय, प्रेम और भरोसा रखें।'
    },
    {
        question: 'दूसरी आज्ञा - मूर्तिपूजा मत कर',
        answer: 'तू अपने लिये कोई मूर्ति खोदकर न बनाना।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम किसी बनायी हुई वस्तु की पूजा-सेवा न करें। न उसका नाम लेवें, न उसके सामने झुकें।'
    },
    {
        question: 'तीसरी आज्ञा - ईश्वर का नाम व्यर्थ न लेना',
        answer: 'परमेश्वर अपने ईश्वर का नाम अकारथ मत ले।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम उसके नाम से श्राप न देवें, न किरिया खावें, न टोना ओझाई करें, न झूठ बोलें, न ठगें। परन्तु सब विपत्तियों में उसकी दोहाई, विनती, स्तुति और धन्यवाद करें।'
    },
    {
        question: 'चौथी आज्ञा - विश्रामवार पवित्र रखना',
        answer: 'विश्रामवार को पवित्र रखने के लिए मत भूल।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम उसका वचन और धर्मोपदेश को तुच्छ न करें परन्तु पवित्र मान कर आनन्द से सुनें और सीखें।'
    },
    {
        question: 'पाँचवी आज्ञा - माता-पिता का आदर',
        answer: 'अपने माता-पिता का आदर कर।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, और अपने माता-पिता और स्वामियों का अपमान न करें, न ही उनको क्रोधित करें। परन्तु उनका सम्मान और सेवा करें, आज्ञा मानें और उनको प्यार करें।'
    },
    {
        question: 'छठवीं आज्ञा - हत्या मत कर',
        answer: 'तू खून न करना।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम अपने पड़ोसी के देह और प्राण को किसी प्रकार की हानि और दुःख न पहुँचावें। परन्तु देह और प्राण की विपत्ति में उसकी सहायता और भलाई करें।'
    },
    {
        question: 'सातवीं आज्ञा - व्यभिचार मत कर',
        answer: 'तू व्यभिचार न करना।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम अपने मन वचन और कर्म में शुद्ध और संयमी होकर जीवन बितावें और हर एक स्त्री-पुरुष, परस्पर प्रेम और आदर करें।'
    },
    {
        question: 'आठवीं आज्ञा - चोरी मत कर',
        answer: 'तू चोरी न करना।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम अपने पड़ोसी का धन-सम्पत्ति न छीनें, न खोटे माल अथवा व्यापार को अपनावें। परन्तु उसके धन-सम्पत्ति और जीविका की वृद्धि और रक्षा में सहायता करें।'
    },
    {
        question: 'नवीं आज्ञा - झूठी साक्षी मत दे',
        answer: 'तू अपने पड़ोसी के विरुद्ध झूठी साक्षी न देना।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम अपने पड़ोसी से झूठ न बोलें, न उसका भेद खोलें, न चुगली, न मिथ्या अपवाद करें। परन्तु उसका पक्ष और आदर करें और जहाँ तक बन पड़े यत्न से उसको भला ठहरावें।'
    },
    {
        question: 'दसवीं आज्ञा - लालच मत कर',
        answer: 'तू अपने पड़ोसी के घर का लालच न करना।',
        explanation: 'हम ईश्वर का भय और प्रेम रखें, कि हम अपने पड़ोसी के घर द्वार, खेत और मवेशियों पर लोभ की दृष्टि न रखें, न बहाना करके उनको अपनावें, न उसकी स्त्री, दास-दासी को फुसलावें या बिगाड़ें। परन्तु यत्न करें कि जो कुछ उसका है, कुशल से उसके पास रहे और उसके काम आवे।'
    }
]

export default function CommandmentsPage({ params }: { params: { id: string } }) {
    const [activeIndex, setActiveIndex] = useState<number | null>(null)
    const [isPlaying, setIsPlaying] = useState(false)

    const toggleAccordion = (index: number) => {
        setActiveIndex(activeIndex === index ? null : index)
    }

    const togglePlay = () => {
        setIsPlaying(!isPlaying)
        // TTS functionality would be integrated here
        if (!isPlaying && activeIndex !== null) {
            const text = commandmentsData[activeIndex].explanation
            if (window.speechSynthesis) {
                const utterance = new SpeechSynthesisUtterance(text)
                utterance.lang = 'hi-IN'
                window.speechSynthesis.speak(utterance)
            }
        } else {
            window.speechSynthesis?.cancel()
        }
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
                        <h1 style={{ margin: 0, fontSize: '1.2rem' }}>1. दस आज्ञा</h1>
                    </div>
                    <button style={{ background: 'transparent', border: 'none', fontSize: '1.2rem' }}>
                        🌙
                    </button>
                </header>

                <div className="container" style={{ padding: '20px' }}>
                    {/* Introduction Card */}
                    <div className="intro-card">
                        <div className="intro-label">परिचय (INTRODUCTION)</div>
                        <div className="intro-text">
                            बाइबल में दी गई दस आज्ञाएँ और उनका अर्थ नीचे दिया गया है। विस्तार से पढ़ने के लिए टेप करें।
                        </div>
                    </div>

                    {/* Accordion List */}
                    <div className="accordion-list">
                        {commandmentsData.map((commandment, index) => (
                            <div
                                key={index}
                                className={`accordion-item ${activeIndex === index ? 'active' : ''}`}
                                onClick={() => toggleAccordion(index)}
                            >
                                <div className="accordion-header">
                                    <div className="badge">{index + 1}</div>
                                    <div className="header-text">
                                        <span className="sub-label">{commandment.question.split(' - ')[0]}</span>
                                        <span className="main-title">{commandment.question.split(' - ')[1]}</span>
                                    </div>
                                    <span className="chevron">▼</span>
                                </div>
                                <div className="accordion-content">
                                    <div className="content-inner">
                                        <p className="standout-text"><strong>{commandment.answer}</strong></p>
                                        <div className="question">इसका क्या अर्थ है?</div>
                                        <p>{commandment.explanation}</p>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>

                    {/* Conclusion Card */}
                    <div className="summary-card">
                        <h3 style={{ color: 'var(--primary)', marginBottom: '12px' }}>आज्ञाओं का निष्कर्ष</h3>
                        <p style={{ marginBottom: '8px', opacity: 0.8, fontSize: '0.9rem' }}>
                            ईश्वर इन सब आज्ञाओं के विषय में क्या कहता है?
                        </p>
                        <div style={{
                            background: 'rgba(255,255,255,0.05)',
                            padding: '16px',
                            borderRadius: '12px',
                            marginBottom: '12px',
                            border: '1px solid rgba(255,255,255,0.1)'
                        }}>
                            <p><em>"ईश्वर यों कहता है कि मैं परमेश्वर तेरा प्रभु ज्वलित ईश्वर हूँ।"</em></p>
                        </div>
                        <p style={{ opacity: 0.9, marginBottom: '12px', fontSize: '0.95rem' }}>
                            इसलिए हम ईश्वर के क्रोध से डरें और उसकी आज्ञाओं के विरुद्ध न करें।
                        </p>
                    </div>
                </div>

                {/* Floating Play Button */}
                <button
                    className="play-fab"
                    onClick={togglePlay}
                    style={{
                        position: 'fixed',
                        bottom: '100px',
                        right: '24px',
                        width: '64px',
                        height: '64px',
                        borderRadius: '20px',
                        background: 'var(--primary)',
                        color: 'black',
                        border: 'none',
                        fontSize: '2rem',
                        cursor: 'pointer',
                        zIndex: 999
                    }}
                >
                    {isPlaying ? '⏸' : '▶'}
                </button>

                {/* Bottom Player */}
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
                        <Link href="/pwa/catechism/2" className="next-title" style={{
                            fontSize: '0.95rem',
                            color: 'white',
                            textDecoration: 'none'
                        }}>
                            प्रार्थना (Prayer)
                        </Link>
                    </div>
                    <div className="player-controls" style={{ display: 'flex', gap: '20px' }}>
                        <button className="control-btn" style={{ background: 'none', border: 'none', color: 'white', fontSize: '1.2rem' }}>
                            ⏮
                        </button>
                        <button
                            onClick={togglePlay}
                            style={{
                                width: '40px',
                                height: '40px',
                                background: 'white',
                                color: 'black',
                                borderRadius: '50%',
                                border: 'none',
                                fontSize: '1.2rem',
                                cursor: 'pointer'
                            }}
                        >
                            {isPlaying ? '⏸' : '▶'}
                        </button>
                        <button className="control-btn" style={{ background: 'none', border: 'none', color: 'white', fontSize: '1.2rem' }}>
                            ⏭
                        </button>
                    </div>
                </div>
            </div>
        </>
    )
}
