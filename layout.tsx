import type { Metadata } from 'next'
import { Playfair_Display, DM_Sans, DM_Mono } from 'next/font/google'
import { Toaster } from 'react-hot-toast'
import './globals.css'

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
})

const dmSans = DM_Sans({
  subsets: ['latin'],
  variable: '--font-body',
  display: 'swap',
})

const dmMono = DM_Mono({
  subsets: ['latin'],
  weight: ['400', '500'],
  variable: '--font-mono',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'Infinite Photos — Cloud Premium',
  description: 'Stockage cloud premium pour vos photos. Conservez, organisez et accédez à vos souvenirs depuis partout.',
  keywords: ['photos', 'cloud', 'stockage', 'galerie', 'albums'],
  openGraph: {
    title: 'Infinite Photos',
    description: 'Stockage cloud premium pour vos photos',
    type: 'website',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr" className={`${playfair.variable} ${dmSans.variable} ${dmMono.variable}`}>
      <body className="bg-ink-950 text-silver-100 font-body antialiased">
        {children}
        <Toaster
          position="bottom-right"
          toastOptions={{
            style: {
              background: '#1a1a26',
              color: '#ededf5',
              border: '1px solid #2e2e4a',
              fontFamily: 'var(--font-body)',
            },
            success: {
              iconTheme: { primary: '#2dd4bf', secondary: '#060608' },
            },
            error: {
              iconTheme: { primary: '#ff6b6b', secondary: '#060608' },
            },
          }}
        />
      </body>
    </html>
  )
}
