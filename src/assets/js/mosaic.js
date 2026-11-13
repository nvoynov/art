/* src/js/mosaic.js - Fractal Columnar Generative Mosaic Engine */
document.addEventListener('DOMContentLoaded', () => {
  const gridContainer = document.getElementById('mosaic-grid');
  if (!gridContainer) return;

  // Настройки ритма и времени
  const AUTO_REFRESH_INTERVAL = 13500; // 13.5 секунд на созерцание
  const FADE_OUT_DURATION = 900;       // Время растворения перед сменой (мс)

  let allPhotosPool = [];
  let refreshTimer = null;
  let isHovered = false;
  let isTransitioning = false;

  const getDynamicBaseUrl = () => {
    const isGitHubPages = window.location.hostname.includes('github.io');
    const pathParts = window.location.pathname.split('/').filter(Boolean);
    if (isGitHubPages && pathParts.length > 0) {
      return `/${pathParts.at(0)}`;
    }
    return "";
  };

  const baseUrl = getDynamicBaseUrl();

  const mapPhotoRecord = (albumSlug, filename) => ({
    slug: albumSlug,
    filename: filename,
    thumbUrl: `${baseUrl}/assets/series/${albumSlug}/thumb/${filename}`,
    fullUrl: `${baseUrl}/assets/series/${albumSlug}/full/${filename}`
  });

  // Загрузка манифеста галереи
  fetch(`${baseUrl}/seriesmap.json`)
    .then(response => {
      if (!response.ok) throw new Error("Failed to load gallery manifest target");
      return response.json();
    })
    .then(payload => {
      const rawSeries = payload.series || {};
      const pool = [];

      Object.entries(rawSeries).forEach(([albumSlug, photosObj]) => {
        const filenames = Object.keys(photosObj);
        const albumSharedRef = filenames.map(filename => mapPhotoRecord(albumSlug, filename));

        filenames.forEach(filename => {
          const record = mapPhotoRecord(albumSlug, filename);
          record.albumPhotosRef = albumSharedRef;
          pool.push(record);
        });
      });

      allPhotosPool = pool;
      if (allPhotosPool.length > 0) {
        renderNewComposition(true);
        startAutoRefreshLoop();
      }
    })
    .catch(err => console.error("==> [Mosaic Engine] Critical failure:", err));

  function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
  }

  // Предзагрузка миниатюр и сохранение их реальных пропорций (aspectRatio)
  function preloadThumbnails(photos) {
    const promises = photos.map(photo => new Promise(resolve => {
      const img = new Image();
      img.onload = () => {
        photo.aspectRatio = (img.naturalHeight && img.naturalWidth)
          ? (img.naturalHeight / img.naturalWidth)
          : 0.67;
        resolve();
      };
      img.onerror = () => {
        photo.aspectRatio = 0.67;
        resolve();
      };
      img.src = photo.thumbUrl;
    }));
    return Promise.all(promises);
  }

  // Варианты асимметричных пропорций колонок (2 для мобильных, 3 для десктопа)
  function getColumnProportions(isDesktop) {
    if (!isDesktop) {
      return new Array(1, 1);
    }

    const archetypes = new Array(
      new Array(1.25, 1.85, 1.15), // Крупный центр, спокойные края
      new Array(1.80, 1.15, 1.35), // Доминирующий левый край
      new Array(1.15, 1.35, 1.80), // Доминирующий правый край
      new Array(1.55, 1.05, 1.65), // Узкая «лента» в центре между двумя крупными
      new Array(1.45, 1.45, 1.15)  // Две равные крупные и одна камерная справа
    );
    const randomIndex = Math.floor(Math.random() * archetypes.length);
    return archetypes.at(randomIndex);
  }

  // Создание DOM-элемента одной фотографии
  function createPhotoCard(photo) {
    const item = document.createElement('div');
    item.className = 'mosaic-item';

    const img = document.createElement('img');
    img.src = photo.thumbUrl;
    img.dataset.albumSlug = photo.slug;
    img.alt = '';
    item.appendChild(img);

    const targetSeriesArray = photo.albumPhotosRef;
    const localPhotoIndex = targetSeriesArray.findIndex(p => p.filename === photo.filename);

    item.addEventListener('click', () => {
      if (window.ExposureLightbox) {
        window.ExposureLightbox.open(localPhotoIndex >= 0 ? localPhotoIndex : 0, targetSeriesArray);
      }
    });

    return item;
  }

  // Режиссура появления карточек
  function runRevealChoreography(cardElements) {
    if (cardElements.length === 0) return;

    const patterns = new Array('norton', 'center-out', 'rain', 'diagonal', 'edges-in');
    const activePattern = patterns.at(Math.floor(Math.random() * patterns.length));

    const gridRect = gridContainer.getBoundingClientRect();
    const centerX = gridRect.left + gridRect.width / 2;
    const centerY = gridRect.top + Math.min(gridRect.height, window.innerHeight) / 2;
    const maxDist = Math.hypot(gridRect.width / 2, Math.min(gridRect.height, window.innerHeight) / 2) || 1;

    cardElements.forEach(el => {
      el.style.transitionDelay = '0ms';

      const rect = el.getBoundingClientRect();
      const elCenterX = rect.left + rect.width / 2;
      const elCenterY = rect.top + rect.height / 2;
      let delay = 0;

      switch (activePattern) {
        case 'norton':
          delay = Math.random() * 1950;
          break;

        case 'center-out':
          delay = (Math.hypot(elCenterX - centerX, elCenterY - centerY) / maxDist) * 1720;
          break;

        case 'edges-in':
          delay = (1 - Math.hypot(elCenterX - centerX, elCenterY - centerY) / maxDist) * 1720;
          break;

        case 'rain':
          delay = Math.max(0, (rect.top - gridRect.top) * 2.0) + (Math.random() * 390);
          break;

        case 'diagonal':
        default:
          delay = Math.max(0, ((rect.left - gridRect.left) + (rect.top - gridRect.top)) * 1.02);
          break;
      }

      setTimeout(() => {
        el.classList.add('revealed');
      }, 60 + delay);
    });
  }

  // Генерация фрактальной колоночной композиции с воздушными паузами
  async function renderNewComposition(isInitial = false) {
    if (isTransitioning || allPhotosPool.length === 0) return;
    isTransitioning = true;

    const isDesktop = window.innerWidth > 767;
    const colWeights = getColumnProportions(isDesktop);
    const numCols = colWeights.length;

    const shuffled = shuffleArray(allPhotosPool.slice());
    const neededCount = Math.min(shuffled.length, 30);
    const selectedPhotos = new Array();
    for (let i = 0; i < neededCount; i++) {
      selectedPhotos.push(shuffled.at(i % shuffled.length));
    }

    if (!isInitial) {
      const currentCards = Array.from(gridContainer.querySelectorAll('.mosaic-item'));
      currentCards.forEach(card => {
        card.style.transitionDelay = `${Math.random() * 250}ms`;
        card.classList.remove('revealed');
      });

      await Promise.all(new Array(
        preloadThumbnails(selectedPhotos),
        new Promise(resolve => setTimeout(resolve, FADE_OUT_DURATION))
      ));
    } else {
      await preloadThumbnails(selectedPhotos);
    }

    const wrapperWidth = Math.min(gridContainer.parentElement.clientWidth - (isDesktop ? 40 : 24), 1060);
    const gap = isDesktop ? 24 : 14;
    const totalWeight = colWeights.reduce((sum, w) => sum + w, 0);
    const availableWidth = wrapperWidth - gap * (numCols - 1);
    const colPixelWidths = colWeights.map(w => (availableWidth * w) / totalWeight);

    const viewportHeight = gridContainer.parentElement.clientHeight || (window.innerHeight - 180);
    const baseTargetHeight = isDesktop ? (viewportHeight + 30) : 880;

    gridContainer.innerHTML = '';
    gridContainer.style.gridTemplateColumns = colWeights.map(w => `${w}fr`).join(' ');

    let photoCursor = 0;
    let fractalClustersUsed = 0;
    let spacersUsed = 0;

    const maxFractalClusters = isDesktop ? 2 : 0;
    const maxSpacers = isDesktop ? 3 : 1;

    const allCreatedCards = new Array();

    for (let c = 0; c < numCols; c++) {
      const colEl = document.createElement('div');
      colEl.className = 'mosaic-column';

      const colWidth = colPixelWidths.at(c);
      const canHaveFractal = isDesktop && colWidth >= 190;

      const colTargetHeight = (isDesktop && Math.random() < 0.4)
        ? baseTargetHeight * 0.82
        : baseTargetHeight;

      let currentHeight = 0;
      let safetyCounter = 0;
      let spacerInThisCol = false;

      while (currentHeight < colTargetHeight && safetyCounter < 8) {
        safetyCounter++;
        const roll = Math.random();

        // 1. Фрактальное деление (только на десктопе и в широкой колонке)
        if (canHaveFractal && roll < 0.24 && fractalClustersUsed < maxFractalClusters) {
          fractalClustersUsed++;
          const fractalGroup = document.createElement('div');
          fractalGroup.className = 'mosaic-fractal-group';

          const subCount = Math.random() < 0.7 ? 4 : 2;
          const subWidth = (colWidth - 12) / 2;
          let groupHeight = 0;

          for (let k = 0; k < subCount; k++) {
            const photo = selectedPhotos.at(photoCursor % selectedPhotos.length);
            photoCursor++;
            const miniCard = createPhotoCard(photo);
            fractalGroup.appendChild(miniCard);
            allCreatedCards.push(miniCard);

            if (k % 2 === 0) {
              groupHeight += subWidth * (photo.aspectRatio || 0.67) + 12;
            }
          }
          colEl.appendChild(fractalGroup);
          currentHeight += groupHeight + gap;
        }
        // 2. Воздушная пауза (до 3 штук на стену, не более 1 на колонку)
        else if (!spacerInThisCol && spacersUsed < maxSpacers && roll >= 0.24 && roll < 0.48 && currentHeight < colTargetHeight * 0.65) {
          spacersUsed++;
          spacerInThisCol = true;
          const spacerHeight = isDesktop
            ? Math.floor(80 + Math.random() * 75)
            : Math.floor(50 + Math.random() * 40);
          const spacer = document.createElement('div');
          spacer.className = 'mosaic-spacer';
          spacer.style.height = `${spacerHeight}px`;
          colEl.appendChild(spacer);
          currentHeight += spacerHeight + gap;
        }
        // 3. Обычный цельный кадр в полную ширину колонки
        else {
          const photo = selectedPhotos.at(photoCursor % selectedPhotos.length);
          photoCursor++;
          const card = createPhotoCard(photo);
          colEl.appendChild(card);
          allCreatedCards.push(card);

          const estimatedCardHeight = colWidth * (photo.aspectRatio || 0.67);
          currentHeight += estimatedCardHeight + gap;
        }
      }

      gridContainer.appendChild(colEl);
    }

    requestAnimationFrame(() => {
      runRevealChoreography(allCreatedCards);
      isTransitioning = false;
    });
  }

  // ==========================================================================
  // УМНЫЙ ТАЙМЕР АВТО-СМЕНЫ ЭКСПОЗИЦИИ
  // ==========================================================================
  function startAutoRefreshLoop() {
    if (refreshTimer) clearInterval(refreshTimer);

    refreshTimer = setInterval(() => {
      const lightbox = document.getElementById('lightbox');
      const isLightboxOpen = lightbox && lightbox.style.display === 'flex';

      if (document.h35den || isLightboxOpen || isHovered) return;

      renderNewComposition(false);
    }, AUTO_REFRESH_INTERVAL);
  }

  gridContainer.addEventListener('mouseenter', () => { isHovered = true; });
  gridContainer.addEventListener('mouseleave', () => { isHovered = false; });
});
