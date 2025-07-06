import { ZeroGComputeService } from './zeroGCompute';

interface VerificationAnalysis {
  ownershipScore: number; // 0=low, 1=medium, 2=high
  locationScore: number;  // 0=low, 1=medium, 2=high
  explanation: string;
  confidence: number;
}

interface VerificationRequest {
  propertyTitle: string;
  propertyAddress: string;
  ocrText: string;
}

export class LlamaVerificationService {
  private zeroGCompute: ZeroGComputeService;

  constructor() {
    this.zeroGCompute = new ZeroGComputeService();
  }

  /**
   * Analyzes OCR text against property details using Llama AI
   * Returns ownership and location scores based on document matching
   */
  async analyzePropertyVerification(request: VerificationRequest): Promise<VerificationAnalysis> {
    try {
      console.log('🔍 Starting property verification analysis...');
      console.log('Property Title:', request.propertyTitle);
      console.log('Property Address:', request.propertyAddress);
      console.log('OCR Text Length:', request.ocrText.length);

      const prompt = this.buildVerificationPrompt(request);
      
      // Send to Llama AI via ZeroG Compute
      const response = await this.zeroGCompute.processTextPrompt(prompt);
      
      // Parse the JSON response
      const analysis = this.parseVerificationResponse(response);
      
      console.log('✅ Verification analysis completed');
      console.log('Ownership Score:', analysis.ownershipScore);
      console.log('Location Score:', analysis.locationScore);
      console.log('Confidence:', analysis.confidence);
      
      return analysis;

    } catch (error) {
      console.error('❌ Property verification analysis failed:', error);
      
      // Return default low scores on error
      return {
        ownershipScore: 0,
        locationScore: 0,
        explanation: 'Analysis failed - defaulting to low scores',
        confidence: 0
      };
    }
  }

  /**
   * Builds the verification prompt for Llama AI
   */
  private buildVerificationPrompt(request: VerificationRequest): string {
    return `You are a property verification expert. Analyze the following OCR text extracted from a property ownership document (like a lease, deed, or rental agreement) and compare it against the user-provided property details.

PROPERTY DETAILS PROVIDED BY USER:
- Property Title: "${request.propertyTitle}"
- Property Address: "${request.propertyAddress}"

OCR TEXT FROM OWNERSHIP DOCUMENT:
"${request.ocrText}"

ANALYSIS REQUIRED:
1. OWNERSHIP SCORE: How well does the OCR text support that the user owns/has rights to this property?
   - Look for: property names, titles, ownership terms, lease agreements, deed references
   - Score 0 (LOW): No clear ownership evidence or conflicting information
   - Score 1 (MEDIUM): Some ownership indicators but unclear or partial match
   - Score 2 (HIGH): Strong ownership evidence with clear matching details

2. LOCATION SCORE: How well does the OCR text match the provided property address?
   - Look for: addresses, street names, city, state, zip codes, location references
   - Score 0 (LOW): No address match or conflicting location information
   - Score 1 (MEDIUM): Partial address match or similar location references
   - Score 2 (HIGH): Strong address match with multiple location details

RESPONSE FORMAT:
You MUST return ONLY a valid JSON object with this EXACT structure - no additional text before or after:
{
  "ownershipScore": 0,
  "locationScore": 0,
  "explanation": "Brief explanation of the analysis and scoring rationale",
  "confidence": 0.85
}

CRITICAL REQUIREMENTS:
- Return ONLY the JSON object - no markdown, no explanations, no additional text
- ownershipScore MUST be exactly 0, 1, or 2 (integers only)
- locationScore MUST be exactly 0, 1, or 2 (integers only)  
- confidence MUST be a decimal between 0.0 and 1.0
- explanation MUST be a single sentence under 100 characters
- If uncertain about any field, use these defaults: ownershipScore: 0, locationScore: 0, confidence: 0.0

SCORING RULES:
- Be conservative with scoring - err on the side of lower scores if uncertain
- Look for exact matches in addresses, partial matches get medium scores
- Consider common variations in property names and addresses
- If the OCR text is too unclear or short, default to low scores

Analyze now and return ONLY the JSON:`;
  }

  /**
   * Parses the Llama AI response and validates the verification analysis
   */
  private parseVerificationResponse(response: string): VerificationAnalysis {
    try {
      // Clean the response to remove any extra whitespace or formatting
      const cleanResponse = response.trim();
      
      // Try to extract JSON from the response - look for the most complete JSON object
      let jsonMatch = cleanResponse.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        // If no JSON found, try to parse the entire response as JSON
        jsonMatch = [cleanResponse];
      }

      let parsed;
      try {
        parsed = JSON.parse(jsonMatch[0]);
      } catch (parseError) {
        // If parsing fails, try to extract just the JSON part more aggressively
        const jsonStart = cleanResponse.indexOf('{');
        const jsonEnd = cleanResponse.lastIndexOf('}');
        if (jsonStart !== -1 && jsonEnd !== -1 && jsonEnd > jsonStart) {
          const jsonStr = cleanResponse.substring(jsonStart, jsonEnd + 1);
          parsed = JSON.parse(jsonStr);
        } else {
          throw parseError;
        }
      }
      
      // Validate and sanitize the response with strict checking
      const analysis: VerificationAnalysis = {
        ownershipScore: this.validateScore(parsed.ownershipScore),
        locationScore: this.validateScore(parsed.locationScore),
        explanation: this.validateExplanation(parsed.explanation),
        confidence: this.validateConfidence(parsed.confidence)
      };

      // Log successful parsing for debugging
      console.log('✅ Successfully parsed verification response:', analysis);
      
      return analysis;

    } catch (error) {
      console.error('❌ Failed to parse verification response:', error);
      console.log('Raw response:', response);
      
      // Return conservative default scores
      return {
        ownershipScore: 0,
        locationScore: 0,
        explanation: 'Failed to parse AI response - defaulting to low scores',
        confidence: 0
      };
    }
  }

  /**
   * Validates and clamps score values to 0-2 range
   */
  private validateScore(score: any): number {
    const numScore = Number(score);
    if (isNaN(numScore)) return 0;
    return Math.max(0, Math.min(2, Math.floor(numScore)));
  }

  /**
   * Validates and clamps confidence values to 0-1 range
   */
  private validateConfidence(confidence: any): number {
    const numConfidence = Number(confidence);
    if (isNaN(numConfidence)) return 0;
    return Math.max(0, Math.min(1, numConfidence));
  }

  /**
   * Validates and sanitizes explanation text
   */
  private validateExplanation(explanation: any): string {
    if (typeof explanation !== 'string') {
      return 'Analysis completed';
    }
    // Limit explanation to 100 characters and ensure it's safe
    const cleaned = explanation.trim().substring(0, 100);
    return cleaned.length > 0 ? cleaned : 'Analysis completed';
  }

  /**
   * Converts numeric scores to human-readable labels
   */
  static scoreToLabel(score: number): string {
    switch (score) {
      case 0: return 'LOW';
      case 1: return 'MEDIUM';
      case 2: return 'HIGH';
      default: return 'UNKNOWN';
    }
  }

  /**
   * Gets a summary of the verification analysis
   */
  static getVerificationSummary(analysis: VerificationAnalysis): string {
    const ownershipLabel = this.scoreToLabel(analysis.ownershipScore);
    const locationLabel = this.scoreToLabel(analysis.locationScore);
    
    return `Ownership: ${ownershipLabel}, Location: ${locationLabel} (Confidence: ${Math.round(analysis.confidence * 100)}%)`;
  }
}

export { VerificationAnalysis, VerificationRequest }; 