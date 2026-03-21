import { useEffect, useRef, useState } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

/**
 * CanvasScrollSequence: A high-performance frame-by-frame renderer.
 * Uses GSAP Pinning to ensure the sequence is perfectly synced with the scrollbar.
 */
export default function CanvasScrollSequence() {
  const containerRef = useRef<HTMLDivElement>(null);
  const sectionRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const textRef = useRef<HTMLDivElement>(null);
  const [progress, setProgress] = useState(0);
  const imagesRef = useRef<HTMLImageElement[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);

  const frameCount = 120;
  
  const getFramePath = (index: number) => {
    const solarImages = [
      'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?auto=format&fit=crop&q=80&w=1920',
      'https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&q=80&w=1920',
      'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?auto=format&fit=crop&q=80&w=1920',
      'https://images.unsplash.com/photo-1548337138-e87d889cc369?auto=format&fit=crop&q=80&w=1920',
      'https://images.unsplash.com/photo-1559302995-f0a16a50083c?auto=format&fit=crop&q=80&w=1920',
    ];
    
    const skyImages = [
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&q=80&w=1920',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=1920',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&q=80&w=1920',
    ];

    if (index < 60) {
      return solarImages[index % solarImages.length];
    } else {
      return skyImages[index % skyImages.length];
    }
  };

  useEffect(() => {
    let loadedCount = 0;
    const demoFrames = 60; // Increased for better preview smoothness

    for (let i = 0; i < demoFrames; i++) {
      const img = new Image();
      img.src = getFramePath(i);
      img.onload = () => {
        loadedCount++;
        imagesRef.current[i] = img;
        if (i === 0) setIsLoaded(true);
      };
    }
  }, []);

  useEffect(() => {
    if (!containerRef.current || !sectionRef.current || !canvasRef.current || !isLoaded) return;

    const canvas = canvasRef.current;
    const context = canvas.getContext('2d');
    if (!context) return;

    const renderFrame = (index: number) => {
      const currentImages = imagesRef.current;
      let targetIndex = index;
      while (targetIndex >= 0 && !currentImages[targetIndex]) targetIndex--;
      if (targetIndex < 0) {
        targetIndex = index;
        while (targetIndex < frameCount && !currentImages[targetIndex]) targetIndex++;
      }

      if (!currentImages[targetIndex]) return;
      
      const img = currentImages[targetIndex];
      const canvasRatio = canvas.width / canvas.height;
      const imgRatio = img.width / img.height;
      
      let drawWidth, drawHeight, drawX, drawY;

      if (canvasRatio > imgRatio) {
        drawWidth = canvas.width;
        drawHeight = canvas.width / imgRatio;
        drawX = 0;
        drawY = (canvas.height - drawHeight) / 2;
      } else {
        drawWidth = canvas.height * imgRatio;
        drawHeight = canvas.height;
        drawX = (canvas.width - drawWidth) / 2;
        drawY = 0;
      }

      context.clearRect(0, 0, canvas.width, canvas.height);
      context.drawImage(img, drawX, drawY, drawWidth, drawHeight);
    };

    const updateCanvasSize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      renderFrame(Math.floor(progress * (frameCount - 1)));
    };

    window.addEventListener('resize', updateCanvasSize);
    updateCanvasSize();

    const ctx = gsap.context(() => {
      // Create a master timeline for the sequence
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: containerRef.current,
          start: 'top top',
          end: '+=400%', // Scroll for 4x viewport height
          pin: true,
          scrub: 0.1,
          onUpdate: (self) => {
            setProgress(self.progress);
            renderFrame(Math.floor(self.progress * (frameCount - 1)));
          },
        },
      });

      // Animate initial text out
      tl.to(textRef.current, {
        opacity: 0,
        y: -100,
        filter: 'blur(10px)',
        duration: 0.5,
      }, 0);

      // Final reveal transition
      tl.to({}, { duration: 1 }); // Spacer for the sequence to play
    }, containerRef);

    return () => {
      window.removeEventListener('resize', updateCanvasSize);
      ctx.revert();
    };
  }, [isLoaded]);

  return (
    <div ref={containerRef} className="relative w-full bg-black">
      <div ref={sectionRef} className="relative h-screen w-full overflow-hidden flex items-center justify-center">
        {/* The Canvas */}
        <canvas
          ref={canvasRef}
          className="absolute inset-0 w-full h-full object-cover z-0"
        />

        {/* Initial Hook Overlay */}
        <div className="relative z-10 pointer-events-none w-full h-full flex flex-col items-center justify-center px-6">
          {!isLoaded && (
            <div className="flex flex-col items-center space-y-4">
              <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin" />
              <p className="text-white/40 font-mono text-xs uppercase tracking-widest">Initializing Sequence...</p>
            </div>
          )}
          
          <div 
            ref={textRef}
            className={`text-center transition-opacity duration-1000 ${isLoaded ? 'opacity-100' : 'opacity-0'}`}
          >
            <h2 className="text-white text-7xl md:text-[12rem] font-heading font-black tracking-tighter uppercase leading-[0.8] mb-8">
              SOLAR <br />
              <span className="text-primary italic">FUTURE</span>
            </h2>
            <p className="text-white/80 text-xl md:text-3xl font-body tracking-[0.2em] uppercase">
              The Next Evolution of Dehydration
            </p>
          </div>
        </div>

        {/* Final Reveal Overlay (White Flash) */}
        <div 
          className="absolute inset-0 z-20 pointer-events-none"
          style={{ 
            opacity: progress > 0.75 ? (progress - 0.75) * 4 : 0,
            background: 'white'
          }}
        />
        
        {/* Final Welcome Message */}
        <div 
          className="absolute inset-0 z-30 pointer-events-none flex flex-col items-center justify-center px-6"
          style={{ 
            opacity: progress > 0.85 ? (progress - 0.85) * 6.66 : 0,
            transform: `translateY(${(1 - progress) * 100}px)`
          }}
        >
          <span className="text-primary font-bold tracking-[0.5em] uppercase text-sm mb-4">Welcome to</span>
          <h3 className="text-black text-6xl md:text-9xl font-heading font-black uppercase tracking-tighter leading-none text-center">
            HELADRY <br />
            <span className="text-primary italic">SYSTEMS</span>
          </h3>
        </div>

        {/* Visual Scroll Progress Indicator */}
        <div 
          className="absolute bottom-12 left-1/2 -translate-x-1/2 z-40 flex flex-col items-center space-y-4 pointer-events-none transition-opacity duration-500"
          style={{ opacity: progress > 0.95 ? 0 : 1 }}
        >
          <div className="w-48 h-[2px] bg-white/10 rounded-full overflow-hidden">
            <div 
              className="h-full bg-primary transition-all duration-100 ease-out"
              style={{ width: `${progress * 100}%` }}
            />
          </div>
          <span className="text-[10px] text-white/30 font-mono uppercase tracking-[0.3em]">
            Sequence Progress
          </span>
        </div>

        {/* Scroll to Explore Hint */}
        <div 
          className="absolute bottom-12 left-1/2 -translate-x-1/2 z-40 flex flex-col items-center pointer-events-none"
          style={{ opacity: progress > 0.9 ? (progress - 0.9) * 10 : 0 }}
        >
          <div className="w-[1px] h-12 bg-primary animate-bounce mb-4" />
          <span className="text-[10px] text-primary font-bold uppercase tracking-[0.5em] mt-2">
            Scroll to Explore
          </span>
        </div>
      </div>
    </div>
  );
}
