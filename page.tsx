import Link from 'next/link'
import { Camera, Cloud, Lock, Zap, Star, ArrowRight } from 'lucide-react'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-ink-950 noise-overlay">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 glass border-b border-ink-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-aurora-blue to-aurora-teal flex items-center justify-center">
              <Camera className="w-4 h-4 text-ink-950" />
            </div>
            <span className="font-display text-xl font-bold text-silver-50">Infinite Photos</span>
          </div>
          <nav className="flex items-center gap-4">
            <Link href="/auth/login" className="btn-ghost text-sm">Connexion</Link>
            <Link href="/auth/register" className="btn-primary text-sm py-2">
              Commencer
              <ArrowRight className="w-4 h-4" />
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <section className="pt-32 pb-24 px-4 text-center relative overflow-hidden">
        {/* Background glow */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[800px] h-[600px] rounded-full bg-aurora-blue/5 blur-[120px]" />
          <div className="absolute top-1/3 left-1/4 w-[400px] h-[400px] rounded-full bg-aurora-teal/5 blur-[80px]" />
        </div>

        <div className="max-w-4xl mx-auto relative">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-ink-700 border border-ink-500 text-sm text-silver-300 mb-8 animate-fade-in">
            <Star className="w-3.5 h-3.5 text-gold-400" />
            Stockage cloud premium pour vos souvenirs
          </div>

          <h1 className="font-display text-5xl sm:text-6xl lg:text-7xl font-bold text-silver-50 mb-6 leading-tight animate-slide-up">
            Vos photos méritent{' '}
            <span className="gradient-text">l'infini</span>
          </h1>

          <p className="text-xl text-silver-300 max-w-2xl mx-auto mb-10 leading-relaxed animate-fade-in">
            Conservez, organisez et accédez à vos photos depuis n'importe où. 
            Un espace cloud premium, sécurisé et sans limites de souvenirs.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center animate-fade-in">
            <Link href="/auth/register" className="btn-primary px-8 py-4 text-base">
              Essai gratuit 7 jours
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link href="/auth/login" className="btn-secondary px-8 py-4 text-base">
              Se connecter
            </Link>
          </div>

          <p className="mt-6 text-sm text-silver-400">
            7 jours gratuits · 10 Go de stockage · Premium à 10€/mois
          </p>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                icon: Cloud,
                title: 'Stockage illimité',
                desc: '10 Go inclus, extensible selon vos besoins. Vos photos toujours disponibles.',
                color: 'aurora-blue',
              },
              {
                icon: Lock,
                title: 'Sécurité totale',
                desc: 'Chiffrement de bout en bout. Vos photos ne sont visibles que par vous.',
                color: 'aurora-teal',
              },
              {
                icon: Camera,
                title: 'Albums & organisation',
                desc: 'Créez des albums, ajoutez des tags, retrouvez vos photos en secondes.',
                color: 'gold-400',
              },
              {
                icon: Zap,
                title: 'Synchronisation',
                desc: 'Upload rapide depuis tous vos appareils. Synchronisation instantanée.',
                color: 'aurora-blue',
              },
            ].map((feature, i) => (
              <div
                key={i}
                className="p-6 rounded-2xl bg-ink-800 border border-ink-600 hover:border-ink-500 transition-all duration-300 group"
              >
                <div className={`w-12 h-12 rounded-xl bg-${feature.color}/10 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform`}>
                  <feature.icon className={`w-6 h-6 text-${feature.color}`} />
                </div>
                <h3 className="font-semibold text-silver-100 mb-2">{feature.title}</h3>
                <p className="text-sm text-silver-400 leading-relaxed">{feature.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="font-display text-4xl font-bold text-silver-50 mb-4">
            Simple et transparent
          </h2>
          <p className="text-silver-400 mb-12">Commencez gratuitement, passez premium quand vous êtes prêt.</p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 max-w-2xl mx-auto">
            {/* Trial */}
            <div className="p-8 rounded-2xl bg-ink-800 border border-ink-600">
              <div className="text-sm text-silver-400 mb-2">Essai gratuit</div>
              <div className="text-4xl font-display font-bold text-silver-100 mb-1">7 jours</div>
              <div className="text-silver-400 text-sm mb-6">Sans engagement</div>
              <ul className="text-left space-y-3 mb-8 text-sm text-silver-300">
                {['Accès complet', '10 Go de stockage', 'Albums illimités', 'Support par email'].map(f => (
                  <li key={f} className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 rounded-full bg-aurora-teal" />
                    {f}
                  </li>
                ))}
              </ul>
              <Link href="/auth/register" className="btn-secondary w-full">
                Commencer l'essai
              </Link>
            </div>

            {/* Premium */}
            <div className="p-8 rounded-2xl bg-gradient-to-b from-ink-700 to-ink-800 border border-aurora-blue/30 relative">
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-aurora-blue text-ink-950 text-xs font-bold">
                RECOMMANDÉ
              </div>
              <div className="text-sm text-aurora-blue mb-2">Premium</div>
              <div className="text-4xl font-display font-bold text-silver-100 mb-1">
                10€<span className="text-xl text-silver-400">/mois</span>
              </div>
              <div className="text-silver-400 text-sm mb-6">Activation manuelle</div>
              <ul className="text-left space-y-3 mb-8 text-sm text-silver-300">
                {['Tout l\'essai inclus', 'Stockage étendu', 'Priorité support', 'Accès permanent'].map(f => (
                  <li key={f} className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 rounded-full bg-aurora-blue" />
                    {f}
                  </li>
                ))}
              </ul>
              <Link href="/auth/register" className="btn-primary w-full">
                Commencer maintenant
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 border-t border-ink-700">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-md bg-gradient-to-br from-aurora-blue to-aurora-teal flex items-center justify-center">
              <Camera className="w-3 h-3 text-ink-950" />
            </div>
            <span className="font-display font-bold text-silver-300">Infinite Photos</span>
          </div>
          <p className="text-sm text-silver-500">© 2025 Infinite Photos. Tous droits réservés.</p>
        </div>
      </footer>
    </div>
  )
}
