import React, { useState, useEffect } from 'react';

const SolarZoom = () => {
  const [currentFrame, setCurrentFrame] = useState(1);
  const totalFrames = 121;

  useEffect(() => {
    const handleScroll = () => {
      const scrollTop = window.pageYOffset;
      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const scrollPercent = scrollTop / docHeight;
      const frame = Math.min(totalFrames, Math.max(1, Math.floor(scrollPercent * totalFrames) + 1));
      setCurrentFrame(frame);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const frameNumber = currentFrame.toString().padStart(3, '0');
  const imageUrl = `/SolarPanelZoomPNG/ezgif-frame-${frameNumber}.png`;

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        backgroundImage: `url(${imageUrl})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        zIndex: -1,
        pointerEvents: 'none',
      }}
    />
  );
};

export default SolarZoom;