// Verificação opcional de execução real; não participa do build Flutter.
// Veja docs/VALIDACAO.md para instalar o Playwright separadamente.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const base = process.env.APP_URL || 'http://127.0.0.1:7357';
  const output = path.resolve(__dirname, '../docs/screenshots');
  fs.mkdirSync(output, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_EXECUTABLE || '/usr/bin/google-chrome',
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--enable-unsafe-swiftshader'],
  });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, locale: 'pt-BR', timezoneId: 'America/Sao_Paulo' });
  // Nenhuma API ou recurso de outro domínio pode ser necessário para o fluxo.
  const externalRequests = [];
  await context.route('**/*', async (route) => {
    if (new URL(route.request().url()).origin === new URL(base).origin) {
      await route.continue();
    } else {
      externalRequests.push(route.request().url());
      await route.abort();
    }
  });
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  const pause = () => page.waitForTimeout(400);
  const shot = async (name) => {
    await page.mouse.move(0, 0);
    await page.waitForTimeout(700);
    await page.screenshot({ path: path.join(output, name) });
    console.log(`Captura: ${name}`);
  };
  const button = (name) => page.getByRole('button', { name, exact: true });
  const tab = (name) => page.getByRole('tab', { name, exact: true });
  const enableSemantics = async () => {
    await page.locator('flt-semantics-placeholder').evaluate((el) => el.click());
  };
  const select = async (field, value) => {
    await page.getByRole('button', { name: new RegExp(field) }).click();
    await page.getByRole('menuitem', { name: value, exact: true }).click();
  };
  const fillField = async (name, value) => {
    await page.getByRole('textbox', { name: new RegExp('^' + name) }).first().click();
    await page.waitForTimeout(150);
    await page.keyboard.press('Control+A');
    await page.keyboard.insertText(value);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
  };
  const waitFeedback = () => page.waitForTimeout(4500);
  const expectText = async (text) => {
    await page.waitForFunction(expected => Array.from(document.querySelectorAll('flt-semantics, [aria-label], h2, span')).some(el => (el.textContent || '').includes(expected) || (el.getAttribute('aria-label') || '').includes(expected)), text);
  };

  try {
    await page.goto(base);
    await enableSemantics();
    await button('Registrar um problema').waitFor();
    await shot('01-home.png');
    await page.mouse.move(180, 600);
    await page.mouse.wheel(0, 1500);
    await pause();
    await shot('02-home-ods.png');
    await tab('Registros').click();
    await expectText('4 registro(s)');
    await shot('03-listagem.png');

    await button('Novo registro').click();
    await page.setViewportSize({ width: 390, height: 1120 });
    await shot('04-formulario.png');
    await button('Salvar registro').click();
    await expectText('Informe título.');
    await shot('05-validacao.png');

    const originalTitle = 'Calçada danificada perto da escola';
    const editedTitle = 'Calçada recuperada perto da escola';
    await fillField('Título', originalTitle);
    await fillField('Bairro', 'Vila Nova');
    await fillField('Local de referência', 'Rua da Escola, em frente ao número 45');
    await fillField('Descrição', 'A calçada apresenta um buraco que dificulta a circulação de crianças e pessoas com mobilidade reduzida.');
    await select('Categoria', 'Acessibilidade');
    await select('Prioridade', 'Alta');
    await button('Salvar registro').click();
    await pause();
    await expectText('5 registro(s)');
    console.log('PASS: cadastro e atualização da listagem');
    await waitFeedback();
    await page.setViewportSize({ width: 390, height: 844 });

    // Recarrega toda a aplicação para verificar o SQLite do navegador.
    await page.reload();
    await enableSemantics();
    await button('Registrar um problema').waitFor();
    await tab('Registros').click();
    await expectText('5 registro(s)');
    await page.getByRole('button', { name: new RegExp(originalTitle) }).click();
    await page.setViewportSize({ width: 390, height: 1040 });
    await expectText('Detalhes do registro');
    await expectText('Rua da Escola, em frente ao número 45');
    await shot('06-detalhes.png');
    console.log('PASS: persistência após recarregar a página');

    await button('Editar registro').click();
    await page.setViewportSize({ width: 390, height: 1120 });
    await shot('07-edicao.png');
    await page.getByRole('textbox', { name: 'Título', exact: true }).click();
    await pause();
    assert.equal(await page.evaluate(() => document.activeElement.value), originalTitle);
    await fillField('Título', editedTitle);
    await select('Situação', 'Resolvido');
    await button('Salvar alterações').click();
    await expectText(editedTitle);
    await expectText('Resolvido');
    await waitFeedback();
    console.log('PASS: edição preenchida, persistência e atualização dos detalhes');

    await button('Excluir registro').click();
    await expectText('Excluir este registro?');
    await page.setViewportSize({ width: 390, height: 844 });
    await shot('08-confirmacao-exclusao.png');
    await button('Cancelar').click();
    await expectText(editedTitle);
    await button('Voltar').click();
    await tab('Bairros').click();
    const progress = page.getByRole('progressbar');
    await progress.waitFor();
    assert.match(await progress.evaluate(el => el.outerHTML), /40%|aria-valuenow="40"/);
    await shot('09-bairros.png');
    // O bairro novo continua acessível mesmo após resolver o registro.
    await page.getByRole('button', { name: /Vila Nova/ }).click();
    await expectText('1 registro(s)');
    await page.getByRole('button', { name: new RegExp(editedTitle) }).click();
    await page.setViewportSize({ width: 390, height: 1040 });
    await button('Excluir registro').click();
    await button('Excluir registro').click();
    await expectText('Nenhum registro encontrado');
    await waitFeedback();
    console.log('PASS: confirmação cancelada, painel reativo, filtro por bairro e exclusão');

    await tab('Início').click();
    await tab('Registros').click();
    await expectText('4 registro(s)');
    // Esvazia apenas o armazenamento descartável deste contexto do navegador.
    for (const title of ['Bueiro obstruído na praça', 'Descarte irregular de resíduos', 'Rampa de acesso danificada', 'Iluminação da passagem recuperada']) {
      await page.getByRole('button', { name: new RegExp(title) }).click();
      await page.setViewportSize({ width: 390, height: 1120 });
      await button('Excluir registro').click();
      await button('Excluir registro').click();
      await waitFeedback();
    }
    await page.setViewportSize({ width: 390, height: 844 });
    await expectText('Seu bairro começa aqui');
    await shot('10-lista-vazia.png');
    await page.reload();
    await enableSemantics();
    await button('Registrar um problema').waitFor();
    await tab('Registros').click();
    await expectText('0 registro(s)');
    console.log('PASS: exclusão persistente e seed não reaplicado em banco vazio');
    assert.deepEqual(errors, []);
    assert.deepEqual(externalRequests, []);
    console.log('PASS: nenhum erro JavaScript e nenhum recurso externo necessário');
    fs.writeFileSync(path.resolve(__dirname, '../docs/browser-result.json'), JSON.stringify({
      verifiedOn: '2026-11-13',
      browser: await browser.version(),
      result: 'passed',
      checks: ['automatic database and seed', 'create', 'validation', 'read', 'update', 'delete confirmation and cancellation', 'reactive dashboard', 'neighborhood filtering', 'persistence after reload', 'empty state', 'no reseeding', 'no external requests'],
      screenshots: fs.readdirSync(output).filter((name) => name.endsWith('.png')),
      javascriptErrors: errors,
      externalRequests,
    }, null, 2) + '\n');
  } catch (error) {
    console.log('Estado ao falhar:', await page.locator('body').innerText());
    await page.screenshot({path:path.join(output, 'browser-failure.png')});
    throw error;
  } finally {
    await browser.close();
  }
})().catch((error) => { console.error(error); process.exit(1); });
