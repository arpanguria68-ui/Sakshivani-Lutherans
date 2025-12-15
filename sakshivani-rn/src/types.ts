export interface Song {
    id: string;
    title: string;
    lyrics: string;
    category: string;
    year?: string;
    reference?: string;
}

export interface CatechismChapter {
    id: string;
    title: string;
    content: string;
}

export interface Question {
    id: string;
    text: string;
    options: string[];
    correctOptionIndex: number;
    explanation?: string;
    difficulty: 'easy' | 'medium' | 'hard';
}

export type RootStackParamList = {
    Home: undefined;
    Songs: undefined;
    SongDetail: { songId: string };
    Catechism: undefined;
    CatechismChapter: { chapterId: string };
    Quiz: undefined;
    Settings: undefined;
};
