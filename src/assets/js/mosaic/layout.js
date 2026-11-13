/* src/js/mosaic/layout.js - Геометрия колонок, фракталы и анимация проявления */

// Профили геометрии (задел на будущее: можно легко добавлять новые ритмы под разные стратегии)
export const GEOMETRY_PROFILES = {
  default: {
    maxFractalClusters: 2,
    maxSpacers: 2,
    fractalChance: 0.24,
    spacerChance: 0.24,
    steppedBottomChance: 0.40
  }
};

export function getColumnProportions(isDesktop) {
  if (!isDesktop) {
    return;
  }

  const archetypes = [
    [1.25, 1.85, 1.15], // Крупный центр, спокойные края
    [1.80, 1.15, 1.35], // Доминирующий левый край
    [1.15, 1.35, 1.80], // Доминирующий правый край
    [1.55, 1.05, 1.65], // Узкая «лента» в центре между двумя крупными
    [1.45, 1.45, 1.15]  // Две равные крупные и одна камерная справа
  ];
  return archetypes[Math.floor(Math.random() * archetypes.length)];
}

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

export function renderMosaicGrid(gridContainer, columnPhotoLists, colWeights, isDesktop, profileName = 'default') {
  const profile = GEOMETRY_PROFILES[profileName] || GEOMETRY_PROFILES.default;
  const numCols = colWeights.length;

  const wrapperWidth = Math.min(gridContainer.parentElement.clientWidth - (isDesktop ? 40 : 24), 1060);
  const gap = isDesktop ? 24 : 14;
  const totalWeight = colWeights.reduce((sum, w) => sum + w, 0);
  const availableWidth = wrapperWidth - gap * (numCols - 1);
  const colPixelWidths = colWeights.map(w => (availableWidth * w) / totalWeight);

  const viewportHeight = gridContainer.parentElement.clientHeight || (window.innerHeight - 180);
  const baseTargetHeight = isDesktop ? (viewportHeight + 30) : 880;

  gridContainer.innerHTML = '';
  gridContainer.style.gridTemplateColumns = colWeights.map(w => `${w}fr`).join(' ');

  let fractalClustersUsed = 0;
  let spacersUsed = 0;

  const maxFractalClusters = isDesktop ? profile.maxFractalClusters : 0;
  const maxSpacers = isDesktop ? profile.maxSpacers : 1;
  const allCreatedCards = [];

  for (let c = 0; c < numCols; c++) {
    const colEl = document.createElement('div');
    colEl.className = 'mosaic-column';

    const colPhotos = columnPhotoLists[c] || [];
    if (colPhotos.length === 0) continue;

    const colWidth = colPixelWidths[c];
    const canHaveFractal = isDesktop && colWidth >= 190;

    const colTargetHeight = (isDesktop && Math.random() < profile.steppedBottomChance)
      ? baseTargetHeight * 0.82
      : baseTargetHeight;

    let photoCursor = 0;
    let currentHeight = 0;
    let safetyCounter = 0;
    let spacerInThisCol = false;

    while (currentHeight < colTargetHeight && safetyCounter < 8) {
      safetyCounter++;
      const roll = Math.random();

      // 1. Фрактальное деление: 50/50 либо полные 4 миниатюры (2x2), либо «уголок» из 3 миниатюр с пустым слотом
      if (canHaveFractal && roll < profile.fractalChance && fractalClustersUsed < maxFractalClusters) {
        fractalClustersUsed++;
        const fractalGroup = document.createElement('div');
        fractalGroup.className = 'mosaic-fractal-group';

        const isCornerPattern = Math.random() < 0.5;
        const subCount = isCornerPattern ? 3 : 4;
        // Для «уголка» случайно выбираем, где будет нижняя третья карточка: слева (1) или справа (2)
        const thirdCardCol = Math.random() < 0.5 ? 1 : 2;
        const subWidth = (colWidth - 12) / 2;
        let groupHeight = 0;

        for (let k = 0; k < subCount; k++) {
          const photo = colPhotos[photoCursor % colPhotos.length];
          photoCursor++;
          const miniCard = createPhotoCard(photo);

          if (isCornerPattern && k === 2) {
            miniCard.style.gridColumn = String(thirdCardCol);
          }

          fractalGroup.appendChild(miniCard);
          allCreatedCards.push(miniCard);

          if (k % 2 === 0) {
            groupHeight += subWidth * (photo.aspectRatio || 0.67) + 12;
          }
        }

        colEl.appendChild(fractalGroup);
        currentHeight += groupHeight + gap;
      }

      // 2. Воздушная пауза
      else if (
        !spacerInThisCol &&
        spacersUsed < maxSpacers &&
        roll >= profile.fractalChance &&
        roll < (profile.fractalChance + profile.spacerChance) &&
        currentHeight < colTargetHeight * 0.65
      ) {
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
      // 3. Цельный кадр в полную ширину колонки
      else {
        const photo = colPhotos[photoCursor % colPhotos.length];
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

  return allCreatedCards;
}

export function runRevealChoreography(gridContainer, cardElements) {
  if (cardElements.length === 0) return;

  const patterns = ['norton', 'center-out', 'rain', 'diagonal', 'edges-in'];
  const activePattern = patterns[Math.floor(Math.random() * patterns.length)];

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

