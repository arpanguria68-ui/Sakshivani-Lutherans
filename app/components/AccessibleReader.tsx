'use client'

import { useEffect, useRef, useState } from 'react'

interface AccessibleReaderProps {
    contentId: string
    onReady?: () => void
}

export default function AccessibleReader({ contentId, onReady }: AccessibleReaderProps) {
    const [isPlaying, setIsPlaying] = useState(false)
    const [useNeural, setUseNeural] = useState(false)
    const [settings, setSettings] = useState({
        fontSize: 'md',
        lineHeight: 'normal',
        theme: 'default',
        font: 'default',
        rate: 1.0,
        mode: 'auto'
    })

    const synthRef = useRef<SpeechSynthesis | null>(null)
    const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null)
    const audioPlayerRef = useRef<HTMLAudioElement | null>(null)
    const chunksRef = useRef<Array<{ element: HTMLElement, text: string }>>([])
    const currentIndexRef = useRef(0)

    useEffect(() => {
        if (typeof window === 'undefined') return

        synthRef.current = window.speechSynthesis
        audioPlayerRef.current = new Audio()

        // Check for neural server
        checkNeuralServer()

        // Load settings from localStorage
        const saved = localStorage.getItem('readerSettings')
        if (saved) {
            setSettings(JSON.parse(saved))
        }

        // Chunk content
        chunkContent()

        // Inject toolbar
        injectToolbar()

        onReady?.()

        return () => {
            stop()
        }
    }, [contentId])

    const checkNeuralServer = async () => {
        try {
            const response = await fetch('http://localhost:8000/health', {
                method: 'GET',
                signal: AbortSignal.timeout(2000)
            })
            if (response.ok) {
                setUseNeural(true)
                console.log('Neural TTS server available')
            }
        } catch (error) {
            setUseNeural(false)
            console.log('Using native browser TTS')
        }
    }

    const chunkContent = () => {
        const container = document.getElementById(contentId)
        if (!container) return

        const chunks: Array<{ element: HTMLElement, text: string }> = []
        const walker = document.createTreeWalker(
            container,
            NodeFilter.SHOW_ELEMENT,
            {
                acceptNode: (node) => {
                    const el = node as HTMLElement
                    if (el.classList.contains('song-line') ||
                        el.tagName === 'P' ||
                        el.classList.contains('content-inner')) {
                        return NodeFilter.FILTER_ACCEPT
                    }
                    return NodeFilter.FILTER_SKIP
                }
            }
        )

        let node
        while (node = walker.nextNode()) {
            const element = node as HTMLElement
            const text = element.textContent?.trim()
            if (text) {
                chunks.push({ element, text })
            }
        }

        chunksRef.current = chunks
    }

    const play = async () => {
        if (chunksRef.current.length === 0) return

        setIsPlaying(true)

        if (useNeural && settings.mode !== 'native') {
            await playNeural()
        } else {
            playNative()
        }
    }

    const playNeural = async () => {
        const chunk = chunksRef.current[currentIndexRef.current]
        if (!chunk) return

        try {
            const response = await fetch('http://localhost:8000/synthesize', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    text: chunk.text,
                    language: 'hi',
                    rate: settings.rate
                })
            })

            if (response.ok) {
                const blob = await response.blob()
                const url = URL.createObjectURL(blob)

                if (audioPlayerRef.current) {
                    audioPlayerRef.current.src = url
                    audioPlayerRef.current.playbackRate = settings.rate

                    audioPlayerRef.current.onended = () => {
                        chunk.element.classList.remove('reading')
                        currentIndexRef.current++
                        if (currentIndexRef.current < chunksRef.current.length) {
                            playNeural()
                        } else {
                            setIsPlaying(false)
                            currentIndexRef.current = 0
                        }
                    }

                    chunk.element.classList.add('reading')
                    await audioPlayerRef.current.play()
                }
            }
        } catch (error) {
            console.error('Neural TTS error, falling back to native:', error)
            playNative()
        }
    }

    const playNative = () => {
        const chunk = chunksRef.current[currentIndexRef.current]
        if (!chunk) return

        if (synthRef.current) {
            const utterance = new SpeechSynthesisUtterance(chunk.text)
            utterance.lang = 'hi-IN'
            utterance.rate = settings.rate

            // Try to find Hindi voice
            const voices = synthRef.current.getVoices()
            const hindiVoice = voices.find(v => v.lang.startsWith('hi'))
            if (hindiVoice) {
                utterance.voice = hindiVoice
            }

            utterance.onend = () => {
                chunk.element.classList.remove('reading')
                currentIndexRef.current++
                if (currentIndexRef.current < chunksRef.current.length) {
                    playNative()
                } else {
                    setIsPlaying(false)
                    currentIndexRef.current = 0
                }
            }

            chunk.element.classList.add('reading')
            synthRef.current.speak(utterance)
            utteranceRef.current = utterance
        }
    }

    const pause = () => {
        setIsPlaying(false)

        if (useNeural && audioPlayerRef.current) {
            audioPlayerRef.current.pause()
        } else if (synthRef.current) {
            synthRef.current.cancel()
        }
    }

    const stop = () => {
        setIsPlaying(false)
        currentIndexRef.current = 0

        if (useNeural && audioPlayerRef.current) {
            audioPlayerRef.current.pause()
            audioPlayerRef.current.currentTime = 0
        } else if (synthRef.current) {
            synthRef.current.cancel()
        }

        // Remove all highlights
        chunksRef.current.forEach(chunk => {
            chunk.element.classList.remove('reading')
        })
    }

    const changeRate = (newRate: number) => {
        setSettings(prev => ({ ...prev, rate: newRate }))
        localStorage.setItem('readerSettings', JSON.stringify({ ...settings, rate: newRate }))
    }

    const injectToolbar = () => {
        // Toolbar is rendered by React component below
    }

    return (
        <>
            <style jsx global>{`
        @import url('/shared/reader.css');
        
        .reading {
          background-color: rgba(250, 204, 21, 0.3);
          transition: background-color 0.3s;
        }
      `}</style>

            {/* TTS Toolbar */}
            <div className="reader-toolbar visible" style={{
                position: 'fixed',
                bottom: '20px',
                right: '20px',
                background: 'rgba(0, 0, 0, 0.9)',
                borderRadius: '16px',
                padding: '12px 16px',
                display: 'flex',
                gap: '12px',
                alignItems: 'center',
                zIndex: 1000,
                boxShadow: '0 4px 12px rgba(0,0,0,0.3)'
            }}>
                {/* Mode Indicator */}
                <div style={{
                    fontSize: '10px',
                    color: useNeural ? '#4ade80' : '#fbbf24',
                    fontWeight: 'bold'
                }}>
                    {useNeural ? '🎙️ Neural' : '🔊 Native'}
                </div>

                {/* Play/Pause */}
                <button
                    onClick={isPlaying ? pause : play}
                    style={{
                        background: 'white',
                        border: 'none',
                        borderRadius: '50%',
                        width: '40px',
                        height: '40px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: 'pointer',
                        fontSize: '18px'
                    }}
                >
                    {isPlaying ? '⏸' : '▶'}
                </button>

                {/* Stop */}
                <button
                    onClick={stop}
                    style={{
                        background: 'rgba(255,255,255,0.2)',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '8px 12px',
                        color: 'white',
                        cursor: 'pointer',
                        fontSize: '16px'
                    }}
                >
                    ⏹
                </button>

                {/* Speed Control */}
                <select
                    value={settings.rate}
                    onChange={(e) => changeRate(Number(e.target.value))}
                    style={{
                        background: 'rgba(255,255,255,0.2)',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '8px',
                        color: 'white',
                        cursor: 'pointer',
                        fontSize: '12px'
                    }}
                >
                    <option value="0.5">0.5x</option>
                    <option value="0.75">0.75x</option>
                    <option value="1">1x</option>
                    <option value="1.25">1.25x</option>
                    <option value="1.5">1.5x</option>
                    <option value="2">2x</option>
                </select>
            </div>
        </>
    )
}
