-- Create llm_prompts table for dynamic prompt management
CREATE TABLE IF NOT EXISTS llm_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    prompt_template TEXT NOT NULL,
    language VARCHAR(10) NOT NULL DEFAULT 'pt',
    version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    
    CONSTRAINT unique_active_prompt UNIQUE (name, language, is_active)
);

CREATE INDEX IF NOT EXISTS idx_llm_prompts_name_language ON llm_prompts(name, language);
CREATE INDEX IF NOT EXISTS idx_llm_prompts_active ON llm_prompts(is_active);

-- Insert default prompt for narrative generation
INSERT INTO llm_prompts (name, description, prompt_template, language, is_active) 
VALUES (
    'narrative_generation',
    'Prompt for generating tax narrative explanations',
    'Você é um assistente de consultoria fiscal. Gere uma explicação narrativa COMPLETAMENTE EM PORTUGUÊS (Brasil) baseada nos seguintes dados de avaliação.

CRÍTICO: TODA a resposta JSON deve estar COMPLETAMENTE em Português (Brasil):
- O campo "summary" DEVE estar em português
- Todos os campos "scenario_title" e "explanation" em "scenario_explanations" DEVEM estar em português
- Todos os itens em "questions_for_lawyer" DEVEM estar em português
- O campo "disclaimer" DEVE estar em português

NÃO use inglês em nenhuma parte da resposta. TUDO deve estar em Português (Brasil).

Para as explicações dos cenários (scenario_explanations):
- NÃO apenas cite os artigos dos convênios
- PARAFRASEIE o conteúdo dos artigos de forma clara e acessível
- EXPLIQUE o significado prático de cada artigo no contexto do cenário
- FORNEÇA detalhes contextuais que ajudem o usuário a entender as implicações
- Use linguagem clara e profissional, mas acessível

Exemplo de explicação RUIM:
"Conforme o Artigo 4 do Convênio PT-BR, que trata de Residência..."

Exemplo de explicação BOA:
"O Artigo 4 do Convênio PT-BR estabelece os critérios para determinar residência fiscal. 
Em termos práticos, isso significa que você será considerado residente fiscal no país onde:
1) Possui residência permanente disponível, ou
2) Mantém o centro de seus interesses vitais (vínculos pessoais e econômicos mais fortes), ou
3) Permanece habitualmente (mais de 183 dias no ano fiscal).

No seu caso específico, com [X] dias em Portugal e [Y] dias no Brasil, o artigo sugere que..."

Avaliação:
- Avaliação de Residência: %s
- Risco de Gestão Efetiva: %s
- Risco CFC: %s
- Cenários: %d cenários fornecidos%s%s

Gere uma resposta JSON com:
{
  "summary": "Resumo breve da avaliação",
  "scenario_explanations": [
    {
      "scenario_title": "Título do cenário",
      "explanation": "Explicação detalhada CITANDO ESPECIFICAMENTE os números dos artigos dos convênios aplicáveis e PARAFRASEANDO seu conteúdo."
    }
  ],
  "questions_for_lawyer": ["Pergunta 1", "Pergunta 2"],
  "disclaimer": "Texto de aviso legal"
}',
    'pt',
    true
) ON CONFLICT DO NOTHING;
