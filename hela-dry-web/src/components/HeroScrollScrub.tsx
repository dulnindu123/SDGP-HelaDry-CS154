import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

const frameCount = 120;
const currentFrame = (index: number) => 
  `/assets/seq/ezgif-frame-${(index + 1).toString().padStart(3, '0')}.jpg`;

export default function HeroScrollScrub() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const skyBgRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext('2d');
    if (!canvas || !context) return;

    // Use typical 16:9 1080p resolution for drawing base; it will scale via CSS object-cover
    canvas.width = 1920; 
    canvas.height = 1080;

    const images: HTMLImageElement[] = [];
    const airpods = { frame: 0 };

    for (let i = 0; i < frameCount; i++) {
        const img = new Image();
        img.src = currentFrame(i);
        images.push(img);
    }

    const render = () => {
        if (images[airpods.frame] && images[airpods.frame].complete) {
            const img = images[airpods.frame];
            // Fill canvas
            context.clearRect(0, 0, canvas.width, canvas.height);
            // We'll just draw it stretched if it's perfectly 16:9, or use cover logic
            // Assuming the source JPGs are 16:9 or similar. 
            context.drawImage(img, 0, 0, canvas.width, canvas.height);
        }
    };

    images[0].onload = render;

    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top top',
        end: '+=300%', // 300vh allocated for the scrub
        scrub: 1, // 1 second smoothing
        pin: true,
      }
    });

    // 1. Scrub the images
    tl.to(airpods, {
      frame: frameCount - 1,
      snap: 'frame',
      ease: 'none',
      onUpdate: () => requestAnimationFrame(render),
      duration: 1
    });

    // 2. Fade out the text hero content midway
    tl.to(contentRef.current, {
        opacity: 0,
        duration: 0.2,
        ease: 'power1.inOut'
    }, "<0.1"); // Start fading text early

    // 3. At the very end of the sequence, fade in the "Sky" theme global background
    // We achieve the "persistent sky" by making the skyBgRef position: fixed and fade it in
    tl.to(skyBgRef.current, {
        opacity: 1,
        duration: 0.2,
        ease: 'power1.inOut'
    }, "-=0.2");

    // Cleanup
    return () => {
      ScrollTrigger.getAll().forEach(t => t.kill());
    };
  }, []);

  return (
    <>
      {/* Global Fixed Sky Background that activates at the end of the video */}
      <div 
        ref={skyBgRef} 
        className="fixed inset-0 w-full h-full pointer-events-none -z-10 opacity-0 transition-opacity duration-300"
        style={{
            background: 'linear-gradient(to bottom, #8BAFCC 0%, #DCE9EE 100%)' // Generic light sky theme
        }}
      />
      
      <div ref={containerRef} className="relative w-full h-screen bg-black overflow-hidden z-0">
        <canvas 
          ref={canvasRef} 
          className="absolute top-0 left-0 w-full h-full object-cover"
        />
        
        {/* Overlay Text for the Hero */}
        <div ref={contentRef} className="absolute inset-0 flex flex-col items-center justify-center text-white z-10 pointer-events-none">
          <h1 className="text-5xl md:text-8xl font-bold mb-6 tracking-tighter drop-shadow-2xl">
            Smarter Solar Drying
          </h1>
          <p className="text-xl md:text-3xl font-medium opacity-90 drop-shadow-md">
            Preserving Tomorrow
          </p>
        </div>
      </div>
    </>
  );
}
