    const defaultConfig = {
      team_name: "HelaDry",
      team_motto: "\"Innovating Agriculture, Preserving Tomorrow\"",
      team_slogan: "Smart Solar Solutions for Sustainable Farming",
      member_1: "W.K. Dulnindu Saranga – Project Leader",
      member_2: "K.D.W.K. Kiriwattuduwa – Hardware Engineer",
      member_3: "B.M. Asjath Ahamed – Software Developer",
      member_4: "L.G. Drian – UI/UX Designer",
      member_5: "Kabilesh K – Mechanical Design",
      member_6: "Seyed Aman Zahir – Web Developer",
      member_7: "Lorshan Harith Ravichandran – QA Engineer",
      hero_headline: "Smarter Solar Drying for Farmers",
      hero_subtext: "An IoT-enabled solar dehydrator that monitors temperature and humidity in real-time to reduce tomato and fruit waste, helping small-scale farmers preserve their harvest sustainably.",
      problem_title: "The Challenge We're Solving",
      solution_title: "Our Solution – CS-154 Smart Dehydrator",
      features_title: "Key Features",
      cta_headline: "Interested in Partnering, Funding, or Testing This Prototype?",
      cta_button_text: "📧 Contact Project Team",
      footer_text: "© 2024 CS-154 Smart Solar-Powered IoT Dehydrator | Software Development Group Project",
      primary_color: "#00E0FF",
      secondary_color: "#FF9F1C",
      accent_color: "#2EC4B6",
      background_color: "#05111a",
      text_color: "#e2e8f0",
      font_family: "Inter",
      font_size: 16
    };

    async function onConfigChange(config) {
      const customFont = config.font_family || defaultConfig.font_family;
      const baseFontStack = '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
      const baseSize = config.font_size || defaultConfig.font_size;

      document.body.style.fontFamily = `${customFont}, ${baseFontStack}`;
      document.body.style.fontSize = `${baseSize}px`;
      document.body.style.background = config.background_color || defaultConfig.background_color;

      // Update text content
      const elements = {
        'splash-team-name': config.team_name || defaultConfig.team_name,
        'splash-motto': config.team_motto || defaultConfig.team_motto,
        'splash-slogan': config.team_slogan || defaultConfig.team_slogan,
        'splash-member-1': config.member_1 || defaultConfig.member_1,
        'splash-member-2': config.member_2 || defaultConfig.member_2,
        'splash-member-3': config.member_3 || defaultConfig.member_3,
        'splash-member-4': config.member_4 || defaultConfig.member_4,
        'splash-member-5': config.member_5 || defaultConfig.member_5,
        'splash-member-6': config.member_6 || defaultConfig.member_6,
        'splash-member-7': config.member_7 || defaultConfig.member_7,
        'hero-headline': config.hero_headline || defaultConfig.hero_headline,
        'hero-subtext': config.hero_subtext || defaultConfig.hero_subtext,
        'problem-title': config.problem_title || defaultConfig.problem_title,
        'solution-title': config.solution_title || defaultConfig.solution_title,
        'features-title': config.features_title || defaultConfig.features_title,
        'cta-headline': config.cta_headline || defaultConfig.cta_headline,
        'cta-button': config.cta_button_text || defaultConfig.cta_button_text,
        'footer-text': config.footer_text || defaultConfig.footer_text
      };

      Object.keys(elements).forEach(id => {
        const el = document.getElementById(id);
        if (el) el.textContent = elements[id];
      });

      // Apply colors
      const primaryColor = config.primary_color || defaultConfig.primary_color;
      const secondaryColor = config.secondary_color || defaultConfig.secondary_color;
      const accentColor = config.accent_color || defaultConfig.accent_color;
      const backgroundColor = config.background_color || defaultConfig.background_color;
      const textColor = config.text_color || defaultConfig.text_color;

      // Update primary color (blue)
      document.querySelectorAll('.section-title, .hero-text h1, .btn-primary, .feature-icon-box, .timeline-number, .tech-item, .team-card h3, .feature-card h3, .timeline-box h3, .impact-card h3, .nav-brand, .nav-logo').forEach(el => {
        if (el.classList.contains('section-title') || el.classList.contains('hero-text') || el.tagName === 'H1' || el.tagName === 'H3' || el.classList.contains('nav-brand')) {
          el.style.color = primaryColor;
        }
        if (el.classList.contains('btn-primary') || el.classList.contains('feature-icon-box') || el.classList.contains('timeline-number') || el.classList.contains('tech-item') || el.classList.contains('nav-logo')) {
          el.style.background = `linear-gradient(135deg, ${primaryColor} 0%, ${adjustBrightness(primaryColor, -15)} 100%)`;
        }
      });

      // Update secondary color (yellow/orange)
      document.querySelectorAll('.problem-icon-wrapper, .flow-icon, .splash-logo').forEach(el => {
        el.style.background = `linear-gradient(135deg, ${secondaryColor} 0%, ${adjustBrightness(secondaryColor, -15)} 100%)`;
      });

      // Update accent color (green)
      document.querySelectorAll('.impact-number').forEach(el => {
        el.style.background = `linear-gradient(135deg, ${accentColor} 0%, ${adjustBrightness(accentColor, -15)} 100%)`;
        el.style.webkitBackgroundClip = 'text';
        el.style.webkitTextFillColor = 'transparent';
        el.style.backgroundClip = 'text';
      });

      // Update text colors
      document.querySelectorAll('.hero-text p, .problem-card p, .feature-card p, .timeline-box p, .team-card p, .impact-card p').forEach(el => {
        el.style.color = textColor;
      });

      // Apply font sizes proportionally
      document.querySelectorAll('.hero-text h1').forEach(el => el.style.fontSize = `${baseSize * 2.5}px`);
      document.querySelectorAll('.hero-text p').forEach(el => el.style.fontSize = `${baseSize * 1.15}px`);
      document.querySelectorAll('.section-title').forEach(el => el.style.fontSize = `${baseSize * 1.9}px`);
      document.querySelectorAll('.feature-card h3, .timeline-box h3, .team-card h3').forEach(el => el.style.fontSize = `${baseSize * 1.1}px`);
      document.querySelectorAll('.problem-card p, .feature-card p').forEach(el => el.style.fontSize = `${baseSize * 1.05}px`);
    }

    function adjustBrightness(color, percent) {
      const num = parseInt(color.replace("#",""), 16);
      const amt = Math.round(2.55 * percent);
      const R = Math.max(0, Math.min(255, (num >> 16) + amt));
      const G = Math.max(0, Math.min(255, (num >> 8 & 0x00FF) + amt));
      const B = Math.max(0, Math.min(255, (num & 0x0000FF) + amt));
      return "#" + (0x1000000 + R * 0x10000 + G * 0x100 + B).toString(16).slice(1);
    }

    if (window.elementSdk) {
      window.elementSdk.init({
        defaultConfig,
        onConfigChange,
        mapToCapabilities: (config) => ({
          recolorables: [
            {
              get: () => config.background_color || defaultConfig.background_color,
              set: (value) => {
                config.background_color = value;
                window.elementSdk.setConfig({ background_color: value });
              }
            },
            {
              get: () => config.primary_color || defaultConfig.primary_color,
              set: (value) => {
                config.primary_color = value;
                window.elementSdk.setConfig({ primary_color: value });
              }
            },
            {
              get: () => config.secondary_color || defaultConfig.secondary_color,
              set: (value) => {
                config.secondary_color = value;
                window.elementSdk.setConfig({ secondary_color: value });
              }
            },
            {
              get: () => config.accent_color || defaultConfig.accent_color,
              set: (value) => {
                config.accent_color = value;
                window.elementSdk.setConfig({ accent_color: value });
              }
            },
            {
              get: () => config.text_color || defaultConfig.text_color,
              set: (value) => {
                config.text_color = value;
                window.elementSdk.setConfig({ text_color: value });
              }
            }
          ],
          borderables: [],
          fontEditable: {
            get: () => config.font_family || defaultConfig.font_family,
            set: (value) => {
              config.font_family = value;
              window.elementSdk.setConfig({ font_family: value });
            }
          },
          fontSizeable: {
            get: () => config.font_size || defaultConfig.font_size,
            set: (value) => {
              config.font_size = value;
              window.elementSdk.setConfig({ font_size: value });
            }
          }
        }),
        mapToEditPanelValues: (config) => new Map([
          ["team_name", config.team_name || defaultConfig.team_name],
          ["team_motto", config.team_motto || defaultConfig.team_motto],
          ["team_slogan", config.team_slogan || defaultConfig.team_slogan],
          ["member_1", config.member_1 || defaultConfig.member_1],
          ["member_2", config.member_2 || defaultConfig.member_2],
          ["member_3", config.member_3 || defaultConfig.member_3],
          ["member_4", config.member_4 || defaultConfig.member_4],
          ["member_5", config.member_5 || defaultConfig.member_5],
          ["member_6", config.member_6 || defaultConfig.member_6],
          ["member_7", config.member_7 || defaultConfig.member_7],
          ["hero_headline", config.hero_headline || defaultConfig.hero_headline],
          ["hero_subtext", config.hero_subtext || defaultConfig.hero_subtext],
          ["problem_title", config.problem_title || defaultConfig.problem_title],
          ["solution_title", config.solution_title || defaultConfig.solution_title],
          ["features_title", config.features_title || defaultConfig.features_title],
          ["cta_headline", config.cta_headline || defaultConfig.cta_headline],
          ["cta_button_text", config.cta_button_text || defaultConfig.cta_button_text],
          ["footer_text", config.footer_text || defaultConfig.footer_text]
        ])
      });

      onConfigChange(window.elementSdk.config);
    } else {
      onConfigChange(defaultConfig);
    }

    // Splash screen animation
    window.addEventListener('load', () => {
      setTimeout(() => {
        document.getElementById('splash-screen').classList.add('fade-out');
        document.querySelector('.app-wrapper').classList.add('visible');
      }, 4000);
    });

    // Hamburger menu toggle
    const hamburger = document.getElementById('hamburger');
    const navMenu = document.getElementById('nav-menu');

    hamburger.addEventListener('click', () => {
      hamburger.classList.toggle('active');
      navMenu.classList.toggle('active');
    });

    // Close menu when clicking a link
    document.querySelectorAll('.nav-menu a').forEach(link => {
      link.addEventListener('click', () => {
        hamburger.classList.remove('active');
        navMenu.classList.remove('active');
      });
    });

    // Navbar scroll effect
    window.addEventListener('scroll', () => {
      const navbar = document.getElementById('navbar');
      if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
      } else {
        navbar.classList.remove('scrolled');
      }
    });

    // Scroll reveal animations
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -80px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, observerOptions);

    document.querySelectorAll('.problem-card, .feature-card, .timeline-step, .impact-card, .team-card').forEach(el => {
      observer.observe(el);
    });

    // Animated counters for impact section
    const animateCounter = (element) => {
      const target = parseInt(element.getAttribute('data-target'));
      const suffix = target > 50 ? '%' : 'x';
      const duration = 2000;
      const increment = target / (duration / 16);
      let current = 0;

      const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
          element.textContent = target + (target > 10 ? '%' : 'x');
          clearInterval(timer);
        } else {
          element.textContent = Math.floor(current) + (target > 10 ? '%' : 'x');
        }
      }, 16);
    };

    const counterObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && entry.target.textContent === '0') {
          animateCounter(entry.target);
        }
      });
    }, { threshold: 0.5 });

    document.querySelectorAll('.impact-number').forEach(counter => {
      counterObserver.observe(counter);
    });

    // Smooth scroll for nav links
    document.querySelectorAll('.nav-menu a').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href');
        const targetSection = document.querySelector(targetId);
        if (targetSection) {
          const navHeight = document.querySelector('.navbar').offsetHeight;
          const offsetTop = targetSection.offsetTop - navHeight;
          window.scrollTo({
            top: offsetTop,
            behavior: 'smooth'
          });
        }
      });
    });

    // Solar Zoom Scroll Feature
    const solarZoomBg = document.getElementById('solar-zoom-bg');
    const totalFrames = 121;
    let currentFrame = 1;

    const updateZoomImage = () => {
      const scrollTop = window.pageYOffset;
      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const scrollPercent = scrollTop / docHeight;
      const frame = Math.min(totalFrames, Math.max(1, Math.floor(scrollPercent * totalFrames) + 1));
      if (frame !== currentFrame) {
        currentFrame = frame;
        const frameNumber = frame.toString().padStart(3, '0');
        solarZoomBg.style.backgroundImage = `url('/SolarPanelZoomPNG/ezgif-frame-${frameNumber}.png')`;
      }
    };

    window.addEventListener('scroll', updateZoomImage);
    updateZoomImage(); // Set initial image

    (function(){function c(){var b=a.contentDocument||a.contentWindow.document;if(b){var d=b.createElement('script');d.innerHTML="window.__CF$cv$params={r:'9a754526e1fc513a',t:'MTc2NDYyMDI2OS4wMDAwMDA='};var a=document.createElement('script');a.nonce='';a.src='/cdn-cgi/challenge-platform/scripts/jsd/main.js';document.getElementsByTagName('head')[0].appendChild(a);";b.getElementsByTagName('head')[0].appendChild(d)}}if(document.body){var a=document.createElement('iframe');a.height=1;a.width=1;a.style.position='absolute';a.style.top=0;a.style.left=0;a.style.border='none';a.style.visibility='hidden';document.body.appendChild(a);if('loading'!==document.readyState)c();else if(window.addEventListener)document.addEventListener('DOMContentLoaded',c);else{var e=document.onreadystatechange||function(){};document.onreadystatechange=function(b){e(b);'loading'!==document.readyState&&(document.onreadystatechange=e,c())}}}})();


// GSAP scroll-driven solar panel zoom
if (window.gsap) {
  gsap.registerPlugin(ScrollTrigger);

  const solarBg = document.getElementById('solar-zoom-bg');
  if (solarBg) {
    const totalFrames = 121; // adjust to your real frame count
    const framePaths = Array.from({ length: totalFrames }, (_, i) => {
      const frameNumber = String(i + 1).padStart(3, '0');
      // Frames live in web/SolarPanelZoomPNG
      return `SolarPanelZoomPNG/ezgif-frame-${frameNumber}.png`;
    });

    // Preload frames for smoother animation
    framePaths.forEach(src => {
      const img = new Image();
      img.src = src;
    });

    const state = { frame: 0 };
    const renderFrame = () => {
      const index = Math.max(0, Math.min(totalFrames - 1, Math.round(state.frame)));
      solarBg.style.backgroundImage = `url('${framePaths[index]}')`;
    };

    renderFrame(); // initial

    gsap.to(state, {
      frame: totalFrames - 1,
      ease: 'none',
      scrollTrigger: {
        trigger: '#hero',       // start animation at hero
        start: 'top top',
        end: 'bottom top',      // finishes as user scrolls past hero
        scrub: true,            // tie to scroll
      },
      onUpdate: renderFrame,
    });
  }
}    